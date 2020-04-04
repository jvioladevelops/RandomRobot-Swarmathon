 ;----------------------------------------------------------------------------------------------

; Author: Justin Viola
; Title swarmathon2
; Swarmathon 2: Advanced Bio-Inspired Search
; version 1.0

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;    Globals and Properties    ;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;----------------------------------------------------------------------------------------------

 ;;The default agent in Netlogo is a turtle. We want to use robots!
 breed [robots robot]

 ;;Let's load the bitmap extension to use a Mars planet background.
 extensions[ bitmap ]

 ;;We need to keep track of how many rocks are left to gather.
 globals [ numberOfRocks ]

;;Each robot knows some information about itself:
 robots-own [
   ;;Is it in the searching? state?
   searching?

   ;;Is it in the returning? state?
   returning?

   ;;1) Is it usingPheromone?
  usingPheromone?

   ]

 ;;Each patch knows some information about itself:
 patches-own [

   ;;What color they start as.
   baseColor

   ;;2) How much time they have left of pheromone before it evaporates.
  pheromoneCounter


   ]



 ;--------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;       setup           ;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;

 to setup

   ;;Clear all the data for a fresh start
   ca

   ;;Import the background image of Mars
   bitmap:copy-to-pcolors bitmap:import "mars.jpg" true

   ;;Set the global numberOfRocks to 0 to start
   set numberOfRocks 0

   ;; Create a number of robots based on the slider bar. Set their properties
   ;; and robots-own variable values.
   create-robots numberOfRobots [
     set shape "robot"
     set size 8
     set searching? true
     set returning? false

     ;;1) Robots start off not using pheromone.
    set usingPheromone? false

   ]

   ;; Patches remember their starting color
   ask patches [
     set baseColor pcolor

     ;;2) There's no pheromone on the patches yet, so
     ;;   set the counter to 0.
    set pheromoneCounter 0

     ]


   ;;Set some random patches to the color yellow to represent rocks.
   let targetPatches singleRocks
     while [targetPatches > 0][
       ask one-of patches[
         if pcolor != black and pcolor != yellow[
           set pcolor yellow
           set targetPatches targetPatches - 1
         ]
       ]
     ]
     set numberOfRocks (numberOfRocks + singleRocks)


   ;; Make some clusters of 5 rocks.
   let targetClusters clusterRocks
     while [targetClusters > 0][
       ask one-of patches[
         if pcolor != black and pcolor != yellow
            and [pcolor] of neighbors4 != black and [pcolor] of neighbors4 != yellow[
           set pcolor yellow
           ask neighbors4[ set pcolor yellow ]
           set targetClusters targetClusters - 1
         ]
       ]
     ]
     set numberOfRocks (numberOfRocks + (clusterRocks * 5))


   ;;3) Create some larger clusters of 29 rocks.
  let targetLargeClusters largeClusterRocks
  while [targetLargeClusters > 0][
    ask one-of patches[
      if pcolor != black and pcolor != yellow and [pcolor] of patches in-radius 3 != black
      and [pcolor] of patches in-radius 3 != yellow[
        set pcolor yellow
        ask patches in-radius 3 [set pcolor yellow]
        set targetLargeClusters targetLargeClusters - 1
      ]
    ]
  ]
  set numberOfRocks numberOfRocks + (largeClusterRocks * 29)


   ;;Make the base.
   ask patches
   [
     if distancexy 0 0 = 0 [set pcolor green]
   ]

  ;;reset ticks to 0
  reset-ticks

 end

 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;;
 ;;       Go        ;;
 ;;;;;;;;;;;;;;;;;;;;;
 to go

   ;;run the program until all rocks are collected
   if (numberOfRocks > 0)
   [
     ask robots
     [
       ;;These statements control the main behavior of the robots.
       ;; 1) There are two cases where a robot is using pheromone:
       ;;    - It found a sufficient density of rocks and is laying a trail back to the base
       ;;      for other robots to follow.
       ;;    - It picked up a trail at the base and is currently following it.
       ;;    The first case is handled by return-to-base.
       ;;    We'll need to take care of the second here:
       ;;    If a robot is using pheromone but is not currently returning to the base, it
       ;;    must be following a trail.
       if usingPheromone? and not returning? [check-for-trails]
       if searching? [look-for-rocks]
       if returning? [return-to-base]

       ;;Make the robots move.
       wiggle
     ]

     ;;2) Manage the pheromone on the patches.
    ask patches
    [
      if pheromoneCounter = 1[
        set pheromoneCounter 0
        set pcolor baseColor
      ]
      if pheromoneCounter > 1 and pheromoneCounter <= 50 [set pcolor cyan - 13]
      if pheromoneCounter > 50 and pheromoneCounter <= 100 [set pcolor cyan - 10]
      if pheromoneCounter > 0 [set pheromoneCounter pheromoneCounter - 1]
   ]
]
   ;;  The challenge from Swarmathon 1 to get the robots to go back to the base
   ;;  after all rocks are colllected is implemented here.
   if not any? patches with [pcolor = yellow][
     set numberOfRocks 0
     ask robots[
       set searching? false
       set returning? true
       while [pcolor != green][
         return-to-base
         fd 1
       ]
     ]
     stop
   ]
   ;;advance the clock
   tick

 end



 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;
 ;;    wiggle      ;;
 ;;;;;;;;;;;;;;;;;;;;

 to wiggle

   ;; Turn right 0 - maxAngle degrees.
   right random maxAngle

   ;; Turn left 0 - maxAngle degrees.
   left random maxAngle

   ;; Turn around and face the origin if we hit the edge of the planet
   ;; (the patch color is black at the edge of the planet).
   if pcolor = black [ facexy 0 0 ]

   ;; Go forward one patch
   forward 1

 end


 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;
 ;; look-for-rocks ;;
 ;;;;;;;;;;;;;;;;;;;;

 to look-for-rocks
   ;;Ask the 8 patches around the robot if the patch color is yellow
   ask neighbors[
     if pcolor = yellow[
     ;;   If it is, take one rock away,
     ;;   and change the patch color back to its original color.
       set numberOfRocks (numberOfRocks - 1)
       set pcolor baseColor

       ;; The robot asks itself to:
       ;; Turn off searching?
       ;; Turn on returning?
       ;; Set its shape to the one holding the rock.
       ask myself [
         set searching? false
         set returning? true
         set shape "robot with rock"
         ]

       ;; 1) Now count the yellow patches (rocks) around the robot.
       ;; If that number is greater than or equal to 2, the robot
       ;; asks itself to set usingPheromone? to true.
      if count patches in-radius 1 with [pcolor = yellow] >= 2 [
        ask myself [set usingPheromone? true]

     ]
   ]
  ]


 end

 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;
 ;; return-to-base ;;
 ;;;;;;;;;;;;;;;;;;;;

 to return-to-base
 ;; If the patch color is green, we found the base.
 ifelse pcolor = green

 ;; Change the robot's shape to the one without the rock,
 ;; and start searching again.
  [
  set shape "robot"
  set returning? false
  set searching? true

 ;; 2) Set pheromone detection on with probability equal to the slider value.
 ;; If detection is activated, turn on pheromone, turn off searching, and
 ;; check-for-trails.
    set usingPheromone? false
    if random 100 < percentChanceToFollowPheromone[
      set usingPheromone? true
      set searching? false
      check-for-trails
    ]
  ]

 ;; Else, we didn't find the base yet--face the base.
  [
    facexy 0 0

    ;;  1) Lay a pheromone trail back to the base if we are using pheromone.
    ;;  Other robots can pick it up.
    ;;  Be careful not to knock out rocks with the trail!
    ;;  Have the patch set its counter for how long the pheromone lasts.

    if usingPheromone?
    [
      ask patch-here[
        if pcolor != yellow [
          set pcolor cyan
          set pheromoneCounter pheromoneDuration
        ]
      ]
   ]
  ]

 end

 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;;;
 ;; check-for-trails ;;
 ;;;;;;;;;;;;;;;;;;;;;;
 to check-for-trails

   ;; 1) Use an ifelse statement.
   ;; Sense if there are any? trails near the robot (in-radius 5).
   ;; Robots cannot sense the faintest trails, so only check for the strongest and slightly evaporated trails:
   ;; these trails have color cyan or cyan - 10.
  ifelse any? patches in-radius 5 with [(pcolor = cyan) or (pcolor = cyan - 10)]
  [

     ;; 2) If there is at least one patch that has a trail on it, create a variable called target to hold the one that's farthest
     ;; from the origin.
    let target one-of patches in-radius 5 with [(pcolor = cyan) or (pcolor = cyan - 10)] with-max [distancexy 0 0]

     ;; 3) Use a nested ifelse statement.
     ;; Compare the distance from the origin of the target patch to that of the robot.
     ;; If the patch is farther away than the origin than the robot, then set the robot's
     ;; label to "ph" to indicate that it's using pheromone.
    ifelse [distancexy 0 0] of target > [distancexy 0 0] of self [
      set label "ph"
      face target
    ]

     ;; 4) Else, the trail must be evaporating, or it is behind us.
     ;; Call the sub procedure to take us back to search mode.
    [switch-to-search-from-pheromone]
  ]

   ;; 5) There aren't any trails near us.
   ;; Call the sub-procedure to take us back to search mode.
  [switch-to-search-from-pheromone]
 end

 ;; 6) Fill in the sub-procedure.
 ;------------------------------------------------------------------------------------
 to switch-to-search-from-pheromone

   ;; Turn off usingPheromone?
  set usingPheromone? false

   ;; Turn on searching?
  set searching? true

   ;; Set the label back to empty.
  set label ""

 end
