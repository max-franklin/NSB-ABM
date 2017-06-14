;Main code for the ABM

;Zip file w/ model and data:
;https://drive.google.com/a/alaska.edu/file/d/0B6Qg-B9DYEuKVE5EQldZMjUtRlE/view?usp=sharing
;Cory, please allow editing for Henri and myself on the Google Drive (Max)
extensions [ gis array matrix table csv]

__includes["insect.nls" "precip.nls" "NDVI.nls" "caribouPop.nls"]

breed [moose a-moose]
breed [caribou a-caribou]
breed [cisco a-cisco]
breed [char a-char]
breed [whitefish a-whitefish]
breed [centroids centroid]
breed [deflectors deflector]
breed [mem-markers mem-mark]


globals
[

;GIS DATA
  patch-roughness-dataset
  patch-wetness-dataset
  patch-streams-dataset
  patch-elevation-dataset
  patch-ocean-dataset

  ;globals for the NDVI.nls module.
  ndvi-dataset
  vegetation-ndvi-list
  ;ndvi-matrix
  ndvi-max

  patch-vegetation-dataset
  max-roughness

  ;use boxes;
  ; mutation-rate
  ; mutation-amt
  ; learn-rate

  ;Globals Precipitation
  precipitation-dataset
	precipitation-data-list
 	precipitation-max
 precipitation-matrix-number

  ;;Bounds Data
  boundsTestData

  current-season


  adjacency-matrix

  ;Time Info
  year
  day
  hour
  ;;FCM
  base-fcm-caribou
  best-caribou-val


  ;PatchList for movement decisions
  patch-coord-x
  patch-coord-y
  patch-list-exists
  patch-list-utility
  patch-array-iterator
  ;;WORK AROUND NUMBERS;; These numbers are used to work around limitations with the
  ;    NetLogo language

  caribou-pop
  caribou/agent
  r-caribou
  ;;Caribou Activation Control
  ;caribou-cent-dist-cutoff
  ;caribou-util-cutoff

  ;;magic centroid number - A hack to allow comparison with centriod number
  magic-centroid



  ;;;;; HENRI'S GLOBALS ;;;;;
  mosquito-sigma
  oestrid-sigma
  mosquito-means-list
  oestrid-means-list
  mosquito-max-color
  oestrid-max-color
  mosquito-max-tenth-color
  oestrid-max-tenth-color
  mosquito-max
  oestrid-max
  mosquito-max-tenth
  oestrid-max-tenth
  mosquito-mean
  oestrid-mean
  time-of-year

  ;;;; insect modifier
  insect-needs-reset
]

patches-own
[
  wetness
  streams
  ocean
  roughness
  elevation
  boundsTest
  vegetation-type
  ndvi-quality

  ;Patches Precipitation.nls
  precipitation-amt
  prec-paint


  ;;Utility Values
  ;caribou
  caribou-utility-max
  caribou-utility
  caribou-modifier ;modified based on caribou vists. Add decay?

  ;moose
  moose-utility-max
  moose-utility
  ;all
  deflection

  ;;;;; HENRI PATCH VALUES ;;;;;
  prev-insect-val
  mosquito-density
  oestrid-density
  mosquito-scale
  oestrid-scale
  gray-scale
  ;water ;doesn't appear to be used atm, but playing it safe. (Max)
  coast
  ;needed?
  ;bool-ocean
]

centroids-own
[
  avg-insect
  veg-quality
  radius
  cid
  category

]

deflectors-own
[
 ;boolean
 has-applied
 ;patch size
 area-outer
 area-inner
 ;value -- value should be from (0,1]
 deflect-amt
]

turtles-own
[
  hidden-label
]

moose-own
[
  energy
  fd-amt
]

caribou-own
[
  group-size
  radius
  energy
  weight
  fd-amt

  ;;Movement Values in relation to Semeniuk et al
  ;;  differs by being 3x as long compared to Semeniuk. Currently 90 minutes instead of 30 minutes
  ;forage intra-patch
  fga-amt
  ;forage inter-patch
  fge-amt
  ;migrate/taxi
  mg-amt-min
  mg-amt-max
ast-winner-caribou-val
  ;goal patch for foraging
  goal-patch
  goal-reached

  ;FCM
  cog-map
  ;actVals
  util-low
  util-high
  taxi-state
  forage-state
  cent-dist-close
  cent-dist-far

  last-taxi-vals
  last-taxi-index

  last-forage-vals
  last-forage-index

  migrate-limit

  bioenergy

  caribou-cognitive

  ;;Current Centroid
  current-centroid
  ;;CurrentState 0 = foraging 1= migration/taxi
  state
  ;;Last Centroid where the caribou came from
  last-centroid


  centroid-attraction
 ; centroid-attraction-min
 ; centroid-attraction-max
  ;used to determine whether a migration has ended // Boolean
  last-state-migrate
  ;Allows remembering of last visited patches // Boolean
  allowed-to-remember
  ;counter for remembering
  attraction-factor

  last-patch-index
  last-patches
  previous-patch

  test-migration
]

mem-markers-own
[
  caribou-id
]

;wraps to other setup functions
to setup
  clear-all
  set time-of-year 0
  set max-roughness 442.442
  set hour 0
  set day 0
  set year 0
  setup-deflectors
  ;this must be called to apply first deflector values
  go-deflectors

  set-mosquito-means-list
  set-oestrid-means-list
  set-mosquito-mean
  set-oestrid-mean
  set-coastline

  setup-precipitation
  setup-terrain-layers
  setup-caribou-utility
  setup-moose-utility
  setup-moose
  setup-centroids
  setup-caribou
  setup-patch-list
  setup-insect
  set-precipitation-data-list
  reset-ticks
end

to setup-graph



end

to setup-centroids
  let data 0
  let arrdata 0
  file-open "data/AllCentroids.csv"
  let idCounter 0

  while [not file-at-end?]
  [
    set data csv:from-row file-read-line
    set arrdata array:from-list data

    create-centroids 1
    [
      set cid idCounter
      setxy (array:item arrdata 0) (array:item arrdata 1)
      set category (array:item arrdata 2)
    ]
    show idCounter
    set idCounter (idCounter + 1)
  ]

  file-close



end

to setup-caribou

  let caribou-group-number floor(caribou-amt / caribou-group-amt)

  ;set base fcm
  set base-fcm-caribou matrix:make-identity 7
  matrix:set-row base-fcm-caribou 0 [0 0 0 0.5 -0.5 0 0] ;util low
  matrix:set-row base-fcm-caribou 1 [0 0 0 -0.5 0.5 0 0] ;util high
  matrix:set-row base-fcm-caribou 2 [0 0 0 0 -0.5 0.5 -0.5] ;cent close
  matrix:set-row base-fcm-caribou 3 [0 0 0 0 0 0 0.5]   ;cent far
  matrix:set-row base-fcm-caribou 4 [0 0 0 0 0 0 0]
  matrix:set-row base-fcm-caribou 5 [0 0 0 0 0 0 0]
  matrix:set-row base-fcm-caribou 6 [0 0 0 0 0 0 0]


  create-caribou caribou-group-amt
  [
    ;State management
    set last-state-migrate false
    set allowed-to-remember false
    set color blue + 2
    let rxcor random-xcor
    let rycor random-ycor


    ;forage intra-patch
    set fga-amt 135 / 2195 ;SemeniukVal * 3 / patch width&height in meters
    ;forage inter-patch
    set fge-amt 1350 / 2195 ; move-towards new patch, set as goal, check if reached, clear goal.
    ;migrate/taxi
    set mg-amt-min 3000 / 2195
    set mg-amt-max 6000 / 2195

    ;taxi based on upto 3 patches away


    ;;Attraction factor to migrate
    set attraction-factor 15
    set test-migration 0
    set last-patches array:from-list n-values 45 [0]
    set last-patch-index 0

    set last-taxi-vals array:from-list n-values 10 [0]
    set last-taxi-index 0

    set last-forage-vals array:from-list n-values 10 [0]
    set last-forage-index 0


    while[rxcor < -63 or rxcor > 63]
    [
      set rxcor random-xcor
    ]

    while[rycor < -63 or rycor > 63]
    [
      set rycor random-ycor
    ]
    ;Size is radius of herd
    set radius caribou-radius
    set shape "circle 2"
    set size radius

    set current-centroid (random 5 + 1)

    set centroid-attraction set-centroid-attraction

    set group-size caribou-group-amt
    set fd-amt 0.25
   while [not check-location rxcor rycor]
   [
     set rxcor random-xcor
     set rycor random-ycor
   ]
    setxy rxcor rycor

    ;set by group population
    set weight (132 * caribou-group-number)
    set bioenergy (27.5 * caribou-group-number * 1000) ; In kJ


      ;;Edges
  ;array:set graph-edges 0 1.0

;  set cog-map matrix:make-identity 7


  ;;WIP;;
  ;;FCM-caribou end states
  ;Perception
  ; util-low                    ; 0
  ; util-high (inverse of low)  ; 1
  ; cent-close                  ; 2
  ; cent-far                    ; 3
  ;Action
  ; change-cent/taxi state      ; 4
  ; forage-state/               ; 5
  ; cent-attraction             ; 6

;  matrix:set-row cog-map 0 [0 0 0 1 -1 0 0] ;util low
;  matrix:set-row cog-map 1 [0 0 0 -1 1 0 0] ;util high
;  matrix:set-row cog-map 2 [0 0 0 0 -1 1 -1] ;cent close
;  matrix:set-row cog-map 3 [0 0 0 0 0 0 1]   ;cent far
;  matrix:set-row cog-map 4 [0 0 0 0 0 0 0] ;change cent/taxi
;  matrix:set-row cog-map 5 [0 0 0 0 0 0 0] ;forage
;  matrix:set-row cog-map 6 [0 0 0 0 0 0 0] ; cent attraction
   set cog-map matrix:copy base-fcm-caribou

   let rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 0 3 ((matrix:get cog-map 0 3) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 0 4 ((matrix:get cog-map 0 4) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 1 3 ((matrix:get cog-map 1 3) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 1 4 ((matrix:get cog-map 1 4) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 2 4 ((matrix:get cog-map 2 4) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 2 5 ((matrix:get cog-map 2 5) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 2 6 ((matrix:get cog-map 2 6) + rand)

   set rand (random-float (mutate-amt * 2) - mutate-amt)
   matrix:set cog-map 3 6 ((matrix:get cog-map 3 6) + rand)

   if(is-training?)
   [
     setxy -12 -27
   ]

  ]
end



to setup-caribou-utility
  ;pseudo utility val for demonstration
  ask patches [set caribou-utility (random 20 + 1)]


  ;;real utility
  ask patches
  [
    ; Try to keep values [0,1]?

    set caribou-modifier 0

    ;;vegetation value
    let veg-value 0
    let rough-value (roughness / max-roughness)

    ;get insect map from henry
    let insect-value 0
    set prev-insect-val 0

    ;Load from GUI Veg-values
    if(vegetation-type = 2)
    [
      set veg-value caribou-util-type-2
    ]
    if(vegetation-type = 3)
    [
      set veg-value caribou-util-type-3
    ]
    if(vegetation-type = 4)
    [
      set veg-value caribou-util-type-4
    ]
    if(vegetation-type = 5)
    [
      set veg-value caribou-util-type-5
    ]

    if(vegetation-type = 9)
    [
      set veg-value caribou-util-type-9
    ]


    ;Utility follows form of (var * varFactor) + (var2 * var2Factor)
    set caribou-utility ((caribou-veg-factor * veg-value) + (caribou-rough-factor * rough-value) + (caribou-insect-factor * insect-value) - (deflection * caribou-deflection-factor))
   ; show caribou-utility
    ;use this when performing update ;; + (modifier-factor * caribou-modifier)
    ;Prevent divide by 0. Rewrite this later to preven the error in new Function.
    if(caribou-utility  <= 0)
    [

      set caribou-utility 0.0000000001
    ]
    if(ocean = 1)
    [
     set caribou-utility 0.0000000001
    ]
    set caribou-utility-max caribou-utility
  ]
end

to update-caribou-fcm
  ask caribou
  [
    ;look for highest average energy
    ;if this.highest > last.highest
    ;  set last.highest this.highest
    ;change base to this.cog-map
    ;update/reset all agents
    ;use new base-map for all agents
    ; apply mutations


    let best max-one-of caribou [bioenergy]
    if([bioenergy] of best > best-caribou-val or best-caribou-val = 0)
    [
      set base-fcm-caribou matrix:copy [cog-map] of best
      set best-caribou-val [bioenergy] of best
    ]

    ask caribou
    [

      set cog-map matrix:copy base-fcm-caribou

      let rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 0 3 ((matrix:get cog-map 0 3) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 0 4 ((matrix:get cog-map 0 4) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 1 3 ((matrix:get cog-map 1 3) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 1 4 ((matrix:get cog-map 1 4) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 2 4 ((matrix:get cog-map 2 4) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 2 5 ((matrix:get cog-map 2 5) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 2 6 ((matrix:get cog-map 2 6) + rand)

      set rand (random-float (mutate-amt * 2) - mutate-amt)
      matrix:set cog-map 3 6 ((matrix:get cog-map 3 6) + rand)

      setxy -12 -27
    ]


  ]
end
to update-caribou-utility
  ask patches
  [

    if (ocean = 0)
    [
      ;reverse insect value from previous run
      set caribou-utility (caribou-utility + (prev-insect-val * caribou-insect-factor))

      ;combine fly and mosquito density, separate later.
      let insect-val (mosquito-density + oestrid-density) / 2
      set caribou-utility caribou-utility - (insect-val * caribou-insect-factor)
      set prev-insect-val insect-val
      ifelse (count caribou-here = 0)
      [
        if (caribou-modifier > 0)
        [
          set caribou-modifier caribou-modifier - decay-rate
        ]

        if (caribou-modifier < 0)
        [
          set caribou-modifier 0
        ]

        if (caribou-utility + caribou-reutility <= caribou-utility-max)
        [
          set caribou-utility caribou-utility + caribou-reutility
        ]
      ]
      ;Apply caribou-modifier
      [
        set caribou-utility (caribou-utility + (caribou-modifier-factor * caribou-modifier))
      ]
      ;Correct divide by 0 error in new function.
      if(caribou-utility  <= 0)
      [

        set caribou-utility 0.00000001
      ]
    ]

  ]
end

to setup-moose-utility
  ;pseudo utility val for demonstration
  ask patches [set moose-utility (random 20 + 1)]


  ;;real utility
  ask patches
  [
    ; Try to keep values [0,1]?

    ;set moose-modifier 0

    ;;vegetation value
    let veg-value 0
    let rough-value (roughness / max-roughness)

    ;get insect map from henry
    let insect-value 0


    if(vegetation-type = 2)
    [
      set veg-value moose-util-type-2
    ]
    if(vegetation-type = 3)
    [
      set veg-value moose-util-type-3
    ]
    if(vegetation-type = 4)
    [
      set veg-value moose-util-type-4
    ]
    if(vegetation-type = 5)
    [
      set veg-value moose-util-type-5
    ]

    if(vegetation-type = 9)
    [
      set veg-value moose-util-type-9
    ]


    ;same form as caribou-utility
    set moose-utility ((moose-veg-factor * veg-value) + (moose-rough-factor * rough-value) + (moose-insect-factor * insect-value) - (deflection * moose-deflection-factor))
   ; show moose-utility

    if(moose-utility  <= 0)
    [

      set moose-utility 0.0000000001
    ]
    if(ocean = 1)
    [
     set moose-utility 0.0000000001
    ]
    set moose-utility-max moose-utility
  ]
end

to update-moose-utility
  ask patches
  [
    if (ocean = 0)
    [
      ;Insect error? Fails to update properly.
      ;reverse insect value from previous run
      set moose-utility (moose-utility + (prev-insect-val * moose-insect-factor))

      let insect-val (mosquito-density + oestrid-density) / 2
      set moose-utility moose-utility - (insect-val * moose-insect-factor)
      set prev-insect-val insect-val
     ; show prev-insect-val
      if(moose-utility  <= 0)
      [

        set moose-utility 0.00000001
      ]
    ]
  ]
end

;Create list for managing available patches to prevent walking on impossible patches
to setup-patch-list
  ;set arrays to max number of available patches.
  set patch-coord-x array:from-list n-values 8 [0]
  set patch-coord-y array:from-list n-values 8 [0]
  set patch-list-exists array:from-list n-values 8 [0]
  set patch-list-utility array:from-list n-values 8 [0]
  set patch-array-iterator 0
end

to setup-moose
  create-moose moose-amt
  [
    set color brown
    let rxcor random-xcor
    let rycor random-ycor
    set size 2.5

    set fd-amt 1
    ;check location to prevent random spawn on ocean/lake
    while [not check-location rxcor rycor]
   [
     set rxcor random-xcor
     set rycor random-ycor
   ]
    setxy rxcor rycor
  ]
end

to setup-deflectors
  ;create test deflector.
  create-deflectors 1
  [
    setxy 0 0
    set area-outer 15
    set area-inner 152
    set deflect-amt 1
    set has-applied false
  ]


end

;Go, wraps to other go's
to go
 ; set day (ticks mod 365)
  set hour hour + 1.5
  if(hour = 24)
  [
    set hour 0
    set day (day + 1)
    go-ndvi
    if(day > 365)
    [
      if caribouPopMod? = true
      [ go-caribou-pop ]
      set year year + 1
      set day (day mod 365)
    ]
  ]

  go-deflectors
  go-insect
  go-moose
  go-caribou
  go-precipitation
  update-caribou-utility
  update-moose-utility
  go-dynamic-display

  if(is-training? and day = 365)
  [
    update-caribou-fcm
    export-fcm
  ]


  tick
end


to export-fcm
  file-open "FCM-List.txt"
  file-write matrix:to-row-list base-fcm-caribou
  file-close
end

;Apply deflectors, bug with updating adding wrong values
to go-deflectors
  ask deflectors
  [
    if(has-applied = false)
    [
      let steps (area-outer - area-inner)
      let adjust-deflect-amt (deflect-amt / steps)

      let step-count area-outer

      while [step-count > area-inner]
      [
        ask patches in-radius step-count
        [
          set deflection (deflection + adjust-deflect-amt)
        ]

        set step-count (step-count - 1)
      ]

      set has-applied true
    ]
  ]
end


;update caribou/moose display
to go-dynamic-display
  if (show-caribou-utility?)
  [
    display-caribou-utility
  ]

  if (show-moose-utility?)
  [
    display-moose-utility
  ]
end

to go-caribou

;Test migration state, and when to kick out of migration.
; Use centroid attraction factor to control intensity of migration
; Incorporate FCM for migration decisions.

;;;States;;;
; 0 - intra-forage
; 1 - taxi
; 2 - interforage



;actVals
;util-low
;util-high
;taxi-state
;forage-state
;cent-dist-close
;cent-dist-far


;  matrix:set-row cog-map 0 [0 0 0 1 -1 0 0] ;util low
;  matrix:set-row cog-map 1 [0 0 0 -1 1 0 0] ;util high
;  matrix:set-row cog-map 2 [0 0 0 0 -1 1 -1] ;cent close
;  matrix:set-row cog-map 3 [0 0 0 0 0 0 1]   ;cent far
;  matrix:set-row cog-map 4 [0 0 0 0 0 0 0] ;change cent/taxi
;  matrix:set-row cog-map 5 [0 0 0 0 0 0 0] ;forage
;  matrix:set-row cog-map 6 [0 0 0 0 0 0 0] ; cent attraction

let migrate-val 0.2

ask caribou
  [
    set state 2
    let other-state-found false
    let avg-past 0
    let i 0
    while [i < 45]
      [
        set avg-past (avg-past + array:item last-patches i)

        set i (i + 1)
      ]

      ;util high or low activation
      ifelse(avg-past < caribou-util-cutoff and ticks > 720)
      [
        set util-low 1
        set util-high 0

        set taxi-state taxi-state + matrix:get cog-map 1 4
        set forage-state forage-state + matrix:get cog-map 1 3
      ]
      [
       set util-low 0
       set util-high 1

       set taxi-state taxi-state + matrix:get cog-map 1 4
       set forage-state forage-state + matrix:get cog-map 1 3
      ]


      ;increase taxi/migration based on high values util values



      ;Centroid Attraction rate
      set magic-centroid current-centroid
      let cent-agents centroids with [cid = magic-centroid]
      let cent-agent one-of cent-agents
      let temp-dist (distance cent-agent)


      ifelse(temp-dist > caribou-cent-dist-cutoff)
      [
        set cent-dist-close 0
        set cent-dist-far 1

        set centroid-attraction centroid-attraction-max
      ]
      [
        set cent-dist-close 1
        set cent-dist-far 0

        set taxi-state taxi-state + matrix:get cog-map 1 4
        set forage-state forage-state + matrix:get cog-map 1 3

        set centroid-attraction (temp-dist / caribou-cent-dist-cutoff) * centroid-attraction-max
        if(centroid-attraction < centroid-attraction-min)
        [
          set centroid-attraction centroid-attraction-min
        ]

      ]
      if(taxi-state > 1)
      [
        set taxi-state 1
      ]

      if(taxi-state < 0)
      [
        set taxi-state 0
      ]

      ; based on percentages in Semeniuk et al
      ifelse(taxi-state > 0.8)
      [
        ifelse(forage-state > 0.5)
        [
          set state 2
        ]
        [
          set state 1
        ]
      ]
      [
        ifelse(forage-state > 0.5)
        [
          set state 0
        ]
        [
          set state 2
        ]
      ]




      ;other-state-found used to get around if-else limitations
      if(state = 0) ;intra forage
      [
        set fd-amt fga-amt
        set other-state-found true
      ]

      if(state = 1 and not other-state-found);taxi/migrate
      [
        set current-centroid (random 115 + 1)
        ;set centroid-attraction (centroid-attraction * attraction-factor)
        set fd-amt mg-amt-max
        set other-state-found true
      ]

      if(state = 2 and not other-state-found);interforage
      [
        set fd-amt fge-amt
      ]


      ;Move according to state and centroid values
      array:set last-patches last-patch-index [caribou-utility] of patch-here
      set last-patch-index last-patch-index + 1

      if(last-patch-index = 45)
        [
          set last-patch-index 0
        ]

      let p patch-list-caribou-wrapper xcor ycor centroid-attraction cent-agent


      face p
      set previous-patch p
      ask patch-here
      [
        set caribou-modifier caribou-modifier + caribou-modify-amt
      ]

      ;look 1 patch ahead
      ifelse([elevation] of patch-at-heading-and-distance heading 1 > [elevation] of patch-here)
      [
        ;uphill
        ;0.4556 patch distance = 1km
        set bioenergy bioenergy - (3.640 * weight * (fd-amt / 0.4556))
      ]
      [
        set bioenergy bioenergy - (1.293 * weight * (fd-amt / 0.4556))
      ]

      ;Move the agent forward by determined amount
      fd fd-amt

      let acquired-energy caribou-veg-type-energy [vegetation-type] of patch-here * group-size
      set bioenergy bioenergy + acquired-energy

      ifelse(temp-dist > caribou-cent-dist-cutoff)
      [
        set centroid-attraction centroid-attraction-max
      ]
      [
        set centroid-attraction (temp-dist / caribou-cent-dist-cutoff) * centroid-attraction-max
        if(centroid-attraction < centroid-attraction-min)
        [
          set centroid-attraction centroid-attraction-min
        ]
      ]




;      if(state = 0)
;      [
;
;
;        set test-migration (test-migration - 1)
;
;        set magic-centroid current-centroid
;        let cent-agents centroids with [cid = magic-centroid]
;        let cent-agent one-of cent-agents
;
;        ;patch memory
;        let avg-past 0
;        let i 0
;        while [i < 45]
;        [
;          set avg-past (avg-past + array:item last-patches i)
;
;          set i (i + 1)
;        ]
;        ;Ticks used for testing
;        let temp-cent current-centroid
;        if(any? centroids in-radius 2 with [cid = temp-cent])
;        [
;
;
;          if(last-state-migrate = true)
;          [
;            set centroid-attraction (centroid-attraction / attraction-factor)
;            set last-state-migrate false
;            show "END TAXI"
;          ]
;
;
;          set avg-past avg-past / 45
;          ; show avg-past
;          if(avg-past < migrate-val)
;          [
;            show "TAXI"
;            set state 1
;          ]
;        ]
;        array:set last-patches last-patch-index [caribou-utility] of patch-here
;        set last-patch-index last-patch-index + 1
;
;        if(last-patch-index = 45)
;        [
;          set last-patch-index 0
;        ]
;
;        let p patch-list-caribou-wrapper xcor ycor centroid-attraction cent-agent
;
;
;        face p
;        set previous-patch p
;        ask patch-here
;        [
;          set caribou-modifier caribou-modifier + caribou-modify-amt
;        ]
;        fd fd-amt
;      ]
;      ;; Migrate
;     if (state = 1)
;     [
;        ;change centroid, used to test until proper centroids implemented
;        set current-centroid (random 100 + 1)
;        set centroid-attraction (centroid-attraction * attraction-factor)
;        ;temporary values to test taxiing
;        set test-migration 150
;        set state 0
;        set last-state-migrate true
;
;      ]



    ]



end
;Call moose movement wrapper
to go-moose
  ask moose
  [
    let p patch-list-moose-wrapper xcor ycor
    face p
    fd fd-amt
  ]
end
;Obsolete, old random walk.
to move-moose
  let oldx xcor
  let oldy ycor

  rt random 50
  lt random 50

  let gofwd (random 5 + 5.25)
 ; show gofwd

  while [patch-ahead gofwd = nobody]
  [
    set gofwd (random 5 + 5.25)
    rt random 50
    lt random 50
  ]


  let aheadx [pxcor] of patch-ahead gofwd
  let aheady [pycor] of patch-ahead gofwd

  let loop-again true
  while [loop-again]
  [
  ;  show "set new 1"
    set loop-again false
    set aheadx [pxcor] of patch-ahead gofwd
    set aheady [pycor] of patch-ahead gofwd
    while [patch-ahead gofwd = nobody]
    [
     ; show "does not exist"
      set gofwd (random 5 + 5.25)
      rt random 50
      lt random 50
    ]

    while [not check-location aheadx aheady ]
    [
    ;  show "failed check"
      set gofwd (random 5 + 5.25)
      rt random 50
      lt random 50

      while [patch-ahead gofwd = nobody]
      [
        ;show "set new 2"
        set gofwd (random 5 + 5.25)

        rt random 50
        lt random 50
      ]

        set aheadx [pxcor] of patch-ahead gofwd
        set aheady [pycor] of patch-ahead gofwd

      set loop-again true

    ]


  ]

  forward (random 5 + 5.25)
end

;show bounds files
to display-bounds
  cd
  set boundsTestData gis:load-dataset BoundsFile
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of boundsTestData))
  show "loaded"
  show gis:maximum-of boundsTestData
  gis:paint boundsTestData 70
end

;Example graph for movements through harvest areas
to display-protograph
  let proto-dat gis:load-dataset "data/ascBounds/MooseNodes.asc"
  hide-protograph
  let i 0
  while [i < gis:width-of proto-dat] [

    let j 0

    while [j < gis:height-of proto-dat] [
      if (gis:raster-value proto-dat i j > 0) [
        create-turtles 1 [
          set color orange
          set size 3.7
          setxy (((i / 4720) * 129) - 64.5) ((((4720 - j) / 4720) * 129) - 64.5)
          set shape "dot"
          set hidden-label "moose-graph"
        ]
      ]
      set j j + 1
    ]
    set i i + 1
  ]
end

to display-caribou-utility
  ask patches [set pcolor scale-color green caribou-utility 0 3 ]
end

to display-moose-utility
  ask patches [set pcolor scale-color green moose-utility 0 3 ]
end

to hide-protograph
  ask turtles[if hidden-label = "moose-graph" [die]]
end
;Loading of terrain layers. Need perceptation
to setup-terrain-layers

  ;set ndvi-matrix 0 ;initializing to May 1 NDVI layer. Shouldnt be used ofc until May 1 is reached in the model, though..
                    ;need to implement timing for NDVI layer switching. Day 121 = May 1 in the simulation, and day 263 = Oct. 20
                    ;(day 1 = Jan. 1)
  ask patches [ set ndvi-quality 0 ]
  set-ndvi-data-list ;setting up the NDVI list
  if day >= 121 [ go-ndvi ]
  set patch-wetness-dataset gis:load-dataset "data/patches/PatchWetness.asc"
  set patch-streams-dataset gis:load-dataset "data/patches/PatchStreams.asc"
  set patch-elevation-dataset gis:load-dataset "data/patches/PatchElevation.asc"
  set patch-ocean-dataset gis:load-dataset "data/patches/PatchOcean.asc"
  set patch-roughness-dataset gis:load-dataset "data/patches/PatchRoughness.asc"
  set patch-vegetation-dataset gis:load-dataset "data/patches/NorthSlopeVegetation.asc"

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-wetness-dataset))

  gis:apply-raster patch-wetness-dataset wetness
  gis:apply-raster patch-roughness-dataset roughness
  gis:apply-raster patch-streams-dataset streams
  gis:apply-raster patch-elevation-dataset elevation
  gis:apply-raster patch-ocean-dataset ocean
  gis:apply-raster patch-vegetation-dataset vegetation-type
  correct-vegetation
end

;;DISPLAY FUNCTIONS;;

;1 - Dry prostrate-shrub tundra; barrens
;2 - Moist graminoid, prostrate-shrub tundra (moist, non-acidic tundra)
;3 - Moist dwarf-shrub, tussock graminoid tundra (typical acidic, tussock tundra)
;4 - Moist low-shrub tundra; other shrublands
;5 - Wet graminoid tundra
;6 -  Water
;7 - Clouds, ice
;8 - Shadow
;9 - Moist tussock graminoid, dwarf-shrub tundra (moist, cold, acidic, sandy tussock tundra)

to display-vegetation
  ask patches [if (vegetation-type = 1) [set pcolor brown - 2 ]]
  ask patches [if (vegetation-type = 2) [set pcolor (green - 1) ]]
  ask patches [if (vegetation-type = 3) [set pcolor green ]]
  ask patches [if (vegetation-type = 4) [set pcolor (green + 1) ]]
  ask patches [if (vegetation-type = 5) [set pcolor (green + 2) ]]
  ask patches [if (vegetation-type = 6) [set pcolor blue ]]
  ask patches [if (vegetation-type = 7) [set pcolor yellow + 1 ]]
  ask patches [if (vegetation-type = 8) [set pcolor yellow + 1 ]]
  ask patches [if (vegetation-type = 9) [set pcolor (green - 2) ]]
end

to display-streams
  let offsetMin 0
  let offsetMax -125500


  let maxVal gis:maximum-of patch-streams-dataset
  let minVal gis:minimum-of patch-streams-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [set pcolor scale-color red streams minVal maxVal]
end

to display-wetness
  let offsetMin 0
  let offsetMax 0

  let maxVal gis:maximum-of patch-wetness-dataset
  let minVal gis:minimum-of patch-wetness-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [set pcolor scale-color blue wetness minVal maxVal]
end

to display-ocean
  let offsetMin 2
  let offsetMax -1

  let maxVal gis:maximum-of patch-ocean-dataset
  let minVal gis:minimum-of patch-ocean-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [ifelse(ocean = 1)[set pcolor blue - 3][set pcolor white]]; (set pcolor scale-color blue ocean minVal maxVal]
end

to display-roughness
  let offsetMin 0
  let offsetMax -380

  let maxVal gis:maximum-of patch-roughness-dataset
  let minVal gis:minimum-of patch-roughness-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [set pcolor scale-color green roughness minVal maxVal]
end

to display-elevation
  let offsetMin -100
  let offsetMax -400

  let maxVal gis:maximum-of patch-elevation-dataset
  let minVal gis:minimum-of patch-elevation-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [set pcolor scale-color black elevation minVal maxVal]
end

to display-simultaneous
  ;OCEAN
  let offsetMin 2
  let offsetMax -1

  let maxVal gis:maximum-of patch-ocean-dataset
  let minVal gis:minimum-of patch-ocean-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [if(ocean = 1)[set pcolor blue - 2]]

  ;ROUGHNESS
  set offsetMin 0
  set offsetMax -20
  set maxVal gis:maximum-of patch-roughness-dataset
  set minVal gis:minimum-of patch-roughness-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [if(roughness > 0) [set pcolor scale-color green roughness minVal maxVal]]

  ;Wetness
  set offsetMin 0
  set offsetMax 0
  set maxVal gis:maximum-of patch-wetness-dataset
  set minVal gis:minimum-of patch-wetness-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin

  ask patches [if(wetness > 0.15) [set pcolor scale-color blue wetness minVal maxVal]]

  ;STREAMS
  set offsetMin -5000
  set offsetMax -115500

  set maxVal gis:maximum-of patch-streams-dataset
  set minVal gis:minimum-of patch-streams-dataset

  set maxVal maxVal + offsetMax
  set minVal minVal + offsetMin
  ask patches [if(streams > 1000) [set pcolor scale-color red streams minVal maxVal]]
end

to display-precipitation
  ask patches [set pcolor scale-color blue precipitation-amt 0 25]
end

to-report caribou-veg-type-energy [val]

;1 - Dry prostrate-shrub tundra; barrens
;2 - Moist graminoid, prostrate-shrub tundra (moist, non-acidic tundra)
;3 - Moist dwarf-shrub, tussock graminoid tundra (typical acidic, tussock tundra)
;4 - Moist low-shrub tundra; other shrublands
;5 - Wet graminoid tundra
;6 -  Water
;7 - Clouds, ice
;8 - Shadow
;9 - Moist tussock graminoid, dwarf-shrub tundra (moist, cold, acidic, sandy tussock tundra)

  ;values in MJ in patc
  if(val = 1)
  [
    report 0
  ]
  if(val = 2)
  [
    report 0.15 * 48.77 ;(2195m our patch / 45m Semeniuk patch)
  ]
  if(val = 3)
  [
    report 0.15 * 48.77 ;(2195m our patch / 45m Semeniuk patch)
  ]
  if(val = 4)
  [
    report 0.15 * 48.77 ;(2195m our patch / 45m Semeniuk patch)
  ]
  if(val = 5)
  [
    report 0.58 * 48.77 ;(2195m our patch / 45m Semeniuk patch)
  ]
  if(val = 9)
  [
    report 0.365 * 48.77 ;(2195m our patch / 45m Semeniuk patch) average of wetland/shrub
  ]

  ;other patch type
  report 0


end


;;Correction Functions
to correct-vegetation
  ;Removes clouds and cloud shadows
  ask patches
[
  while [(vegetation-type = 7) or (vegetation-type = 8)]
  [

    let rand random 3
    let tempx (rand - 1)
    set rand random 3
    let tempy (rand - 1)
;    show "x"
;    show tempx + pxcor
;    show "y"
;    show tempy + pycor

    if(tempx + pxcor <= 64) and (tempx + pxcor > -65) and (tempy + pycor <= 64) and (tempy + pycor > -65)
    [
      let veg-temp ([vegetation-type] of patch-at tempx tempy)
      if (not(veg-temp = 7) and not(veg-temp = 8))
      [
        set vegetation-type veg-temp
      ]
    ]

  ]
]
end
;Converts NAD27 Coordinates to Patches in the model
to nad-to-patch-pos [x y]
  ;extents of the data used
  let hmin 2099760
  let hmax 2382960
  let wmin -27000
  let wmax 256200

  ;Output of the previous to ensure extents are correct.
  show "NAD83 Height Min and Max"
  show hmin
  show hmax
  show "NAD83 Width Min and Max"
  show wmin
  show wmax

  ;how many nad coordinates per patch height and width
  let nad-per-x (wmax - wmin) / (max-pxcor - min-pxcor)
  let nad-per-y (hmax - hmin) / (max-pycor - min-pycor)

  ;distance of x from the minimum width. Divide by nad-per-x (nad units per x patches) and divide the total by two and subtract
  ;  assumes origin is center.
  let patch-x ((x - wmin) / nad-per-x) - ((max-pxcor - min-pxcor) / 2)
  let patch-y ((y - hmin) / nad-per-y) - ((max-pycor - min-pycor) / 2)
  show "RESULT X Y"
  show patch-x
  show patch-y

end

;CD5 Lat/Long: 70.302618, -151.142401
;Two maps are required, one project in WGS84
; another in the standard NAD27-Alaska
; coordinate grabber in QGIS must be set to WGS84
; long Lat tools allow zooming in Lat/Long to select
; the location and pull the NAD27-Alaska point to convert.
to display-CD5
  hide-CD5
  let patch-x -2.2409039548022633
  let patch-y 8.624632768361579

  create-turtles 1 [
    set color red
    set size 5
    setxy patch-x patch-y
    set shape "dot"
    set label "CD5"
    set label-color red
  ]
end

to hide-CD5
  ask turtles [if label = "CD5" [die]]
end

;Show location of Nuiqsut
to display-nuiqsut
  hide-nuiqsut
  let patch-x 0.38689265536723383
  let patch-y 4.621468926553675

  create-turtles 1 [
    set color green
    set size 5
    setxy patch-x patch-y
    set shape "dot"
    set label "NUIQSUT"
    set label-color green
  ]
end

to hide-nuiqsut
  ask turtles [if label = "NUIQSUT" [die]]
end

;Obsolete, cisco harvest region. Use ASCII files instead, quicker/easier to implement
to display-cisco
  hide-cisco
  let tempx  [
    3.118644067796609
    2.6964971751412463
    2.183050847457622
    1.6515254237288133
    1.0413559322033876
    0.567683615819206
    0.7087005649717497
    0.32949152542373383
    -0.03435028248587457
    0.04564971751412372
    0.12248587570621794
    -0.21694915254236946
    -0.24135593220339047
    -0.7380790960451975
    -1.1181920903954818
    -1.0445197740112988
    -1.1340112994350307
    -1.3491525423728845
    -1.6501694915254248
    -1.6605649717514126
    -1.7943502824858726
  ]

  let tempy [
    5.326101694915252
    4.964519774011293
    4.843389830508471
    5.089265536723161
    4.720451977401126
    4.790960451977398
    5.454011299435024
    5.620790960451984
    5.667796610169489
    7.063502824858759
    8 ;This is not a typo
    8.27435028248587
    8.967231638418085
    9.611751412429385
    10.263954802259889
    11.095593220338984
    11.84271186440678
    12.226440677966096
    12.764293785310741
    13.630734463276838
    14.79728813559322
  ]

  let xpoints array:from-list tempx
  let ypoints array:from-list tempy

  let i 0
  while [i < array:length xpoints] [

    create-turtles 1 [
    set color pink
    set size 2.7
    setxy array:item xpoints i array:item ypoints i
    set shape "dot"
    set hidden-label "cisco"
    ]

    set i i + 1
  ]
end

to hide-cisco
  ask turtles[if hidden-label = "cisco" [die]]
end

;Spawn location checking for better testing.
to-report check-location [x y]
  let ocean-good true
  let wetness-good true
  let elevation-good true

  if x < -64.5 or x > 64.5
  [
    report false
 ;   show "X: "
 ;   show x
  ]

  if y < -64.5 or y > 64.5
  [
    report false
 ;   show "Y: "
;    show y
  ]


  ifelse ([ocean] of patch x y) = 1
 [
   set ocean-good  false
  ; show "ocean false"
 ;  show x
 ;  show y
 ]

  [
    set ocean-good true
  ]

  ifelse ([wetness] of patch x y) > 0.95
  [
    set wetness-good false
 ;   show "wet-false"
 ;   show x
  ;  show y
  ]
  [
    set wetness-good true
  ]

   ifelse ([elevation] of patch x y) > elevation-limit
 [
   set elevation-good  false
;   show "elev-false"
 ]

  [
    set elevation-good true
  ]

   ifelse wetness-good = true and ocean-good = true and elevation-good = true
   [
     report true
   ]
   [
     report false
   ]
end

to-report patch-exists [x y]
  if (x > 64 or x < -64)
  [
    report false
  ]

  if (y > 64 or y < 64)
  [
    report false
  ]

  report true
end

;;Patch List Management Function
;   uses a list of coordinates and patch availability

to-report patch-list-caribou-wrapper [curr-x curr-y attraction target]
  ;build patches
  ;remove bad patches
  ;build/normalize utility values
  ;increase target value

  build-patch-list curr-x curr-y
  remove-nonwalkable-patches caribou-max-elevation caribou-max-wetness
  patch-list-normal-caribou-util
  patch-list-add-attraction attraction target

  let p patch-list-probable
  ;clear the patch-list by calling setup
  setup-patch-list
  report p


end

to-report patch-list-moose-wrapper [curr-x curr-y]

  build-patch-list curr-x curr-y
  remove-nonwalkable-patches moose-max-elevation moose-max-wetness
  patch-list-normal-caribou-util
  patch-list-add-attraction 0 one-of centroids

  let p patch-list-probable
  ;clear the patch-list by calling setup
  setup-patch-list
  report p
end

;Add patches to the patch list by coordinates and existence
to add-patch-list [x y ex]
  array:set patch-coord-x patch-array-iterator x
  array:set patch-coord-y patch-array-iterator y
  array:set patch-list-exists patch-array-iterator ex

  set patch-array-iterator (patch-array-iterator + 1)

  if(patch-array-iterator = 8)
  [
    set patch-array-iterator 0
  ]

; PROCESS -- Probablility? Find patch coordinates? Set Index Number?

; SELECT
end

;Takes world patch coordinates and adds patches to the patch list to be evaluated
to build-patch-list [curr-x curr-y]
  let i -1
  while [i <= 1]
  [
    let j -1
    while [j <= 1]
    [
      if (not(i = 0 and j = 0))
      [
        let temp-x curr-x + i
        let temp-y curr-y + j

       ; show temp-x
       ; show temp-y
        ;If the patch is out of range, it does not exist, else it is in range and does exists
        ifelse(temp-x > 64 or temp-x < -64 or temp-y > 64 or temp-y < -64)
        [
          add-patch-list temp-x temp-y 0
        ]
        [
          add-patch-list temp-x temp-y 1
        ]
      ]
        set j (j + 1)
    ]
    set i (i + 1)
  ]

end


to remove-nonwalkable-patches [max-elevation max-wetness]
  let i 0

  ;Checks if a patch in the list exists and then checks to see it walkable
  ;if the patch is not walkable we set its existence to 0
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      let p patch (patch-list-get-x i) (patch-list-get-y i)

      ;Perform checks here
      if ([ocean] of p = 1)
      [
        set-patch-exists i 0
      ]

      if ([wetness] of p > max-wetness)
      [
        set-patch-exists i 0
      ]

      if ([elevation] of p > max-elevation)
      [
        set-patch-exists i 0
      ]

      if([deflection] of p > 0.95)
      [
        set-patch-exists i 0
      ]

    ]

    set i (i + 1)
  ]
end
;Average the utilty function to be (0,1)
to patch-list-normal-caribou-util
  let utotal 0

  let i 0
  ;get total number
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      let p patch (patch-list-get-x i) (patch-list-get-y i)
      array:set patch-list-utility i ([caribou-utility] of p)
      set utotal (utotal + array:item patch-list-utility i)
    ]
    set i (i + 1)
  ]

  ;as
  set i 0
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      array:set patch-list-utility i (array:item patch-list-utility i / utotal)
    ]
    set i (i + 1)
  ]

end
;Add an attraction to a target variable
to patch-list-add-attraction [attraction target]
  ; this distances stored in a list in the event a diffuse function is needed
  let dist-list array:from-list n-values 8 [0]

  let short-index -1
  let short-val -1


  ; Find the minimum distance from available patches
  let i 0
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      let p patch (patch-list-get-x i) (patch-list-get-y i)
      let temp-dist [distance p] of target
      array:set dist-list i temp-dist

      if(temp-dist < short-val or short-val = -1)
      [
        set short-index i
        set short-val temp-dist
      ]
    ]
    set i (i + 1)
  ]

  ; Add the attraction amount to the patch closes to the target
  if (not(short-index = -1))
  [
    ;TODO: verify this corrected the error by changing i -> short-index
    array:set patch-list-utility short-index (array:item patch-list-utility short-index + attraction)
  ]
  ; Renormalize the utility values
  let utotal 0

  set i 0
  ;get total number
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      let p patch (patch-list-get-x i) (patch-list-get-y i)
      set utotal (utotal + array:item patch-list-utility i)
    ]
    set i (i + 1)
  ]

  ;normalize data set
  set i 0
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      array:set patch-list-utility i (array:item patch-list-utility i / utotal)
    ]
    set i (i + 1)
  ]


end

; Reports back a patch according to the utility values
to-report patch-list-probable
  let prob-list array:from-list n-values 8 [0]
  ;prob-list-index contains the index of the values in the main patch list
  let prob-list-index array:from-list n-values 8 [0]
  let list-index 0

  let i 0
  while [i < 8]
  [
    if(patch-list-get-exist i = 1)
    [
      ifelse(list-index > 0)
      [
        ;if something is already in the list, add the current utility value to the previous probability
        ;set the index to the current value in the utility list
        let prev-value array:item prob-list (list-index - 1)
        array:set prob-list list-index ((array:item patch-list-utility i) + prev-value)
        array:set prob-list-index list-index i
        set list-index (list-index + 1)
      ]
      [
        ; For the first item, just the utility value as the probability
        array:set prob-list list-index (array:item patch-list-utility i)
        array:set prob-list-index list-index i
        set list-index (list-index + 1)
      ]
    ]

    set i (i + 1)
  ]

  ;List index now contains the size of the list which traversed
  ;  smallest probability (first in list == (0.0, 1.0] ) to highes (last in list == 1.00)
  let p-index 0
  let selector ((random 1000 + 1 )/ 1000)

  set i 0
  while [i < list-index]
  [
    if(selector < array:item prob-list i)
    [
      ;set p-index to the index value of the master list
      set p-index array:item prob-list-index i
      ;Patch index found kick out of loop
      set i list-index
    ]
    set i (i + 1)
  ]

  let p-return-x patch-list-get-x p-index
  let p-return-y patch-list-get-y p-index

  ;report back the selected patch
  if(patch-list-get-exist p-index = 1)
  [
    ;show "---------"
    ;show p-return-x
    ;show p-return-y
    report patch p-return-x p-return-y
  ]

  ;something is wrong report center patch as a failsafe
  ;  this can occur during random placement of agents
  report patch 0 0

end

to reset-patch-list

end


;Simple wrappers
to-report patch-list-get-x [index]
  report array:item patch-coord-x index
end

to-report patch-list-get-y [index]
  report array:item patch-coord-y index
end

to-report patch-list-get-exist [index]
  report array:item patch-list-exists index
end

to-report patch-list-get-util [index]
  report array:item patch-list-utility index
end

to set-patch-exists [index value]
  array:set patch-list-exists index value
end

to patch-iterator-override [x]
  set patch-array-iterator x
end

;SET COASTLINE
to set-coastline
  ask patches
  [
     if ocean = 0
     [
        if any? neighbors with [ocean = 1]
        [
           set coast true
        ]
     ]
  ]
end

;SHOW COASTLINE
to show-coastline
   ask patches with [coast = true]
   [
      set pcolor 86
   ]
end

;SET MOSQUITO SCALE
to set-mosquito-scale ;determines the gray scale value for mosquito densities
  let c 0
  while [ c < 10 ]
  [
    if (mosquito-density >= (c * mosquito-max-tenth-color)) and (mosquito-density < ((c + 1) * mosquito-max-tenth-color))
    [ set mosquito-scale (c * 0.5) ]
    set c c + 1
  ]
end

;SET GRAY SCALE
to set-gray-scale ;sets the gray scale values based on the desities present at each patch
   set-mosquito-scale
   set-oestrid-scale
   set gray-scale (mosquito-scale + oestrid-scale)
   set pcolor gray-scale
end

;SET OESTRID SCALE
to set-oestrid-scale ;determines the gray scale value for fly densities
  let k 0
  while [ k < 10 ]
  [
    if (oestrid-density >= (k * mosquito-max-tenth)) and (oestrid-density < ((k + 1) * mosquito-max-tenth))
    [ set oestrid-scale (k * 0.5) ]
    set k k + 1
  ]
end

;REMOVE COASTLINE
to remove-coastline
  ask patches with [coast = true]
  [
     set-gray-scale
  ]
end

;REDUCE COAST
to reduce-coast
  ask patches with [coast = true]
  [
    ask patches in-radius 2 with [ocean = 0]
    [
         set mosquito-density (random-float (.5 * mosquito-max-tenth))
        set oestrid-density (random-float (.5 * oestrid-max-tenth))
        set-gray-scale
        ;set a coast reduce variable to just check before distributions are made
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
278
10
790
523
-1
-1
3.91
1
10
1
1
1
0
0
0
1
-64
64
-64
64
0
0
1
ticks
30.0

BUTTON
77
57
151
90
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
80
141
220
174
Show Elevation
display-elevation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
82
180
220
213
Show Streams
display-streams
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
82
220
221
253
Show TRI
display-roughness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
83
259
221
292
Show Wetness
display-wetness
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
83
297
222
330
Show Ocean
display-ocean
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
69
349
233
382
Show Combination
display-simultaneous
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1160
29
1289
62
Show Nuiqsut
display-Nuiqsut
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1160
69
1289
102
Show CD5
display-CD5
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1161
109
1287
142
Show Cisco
display-cisco
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1296
28
1420
61
Hide Nuiqsut
hide-nuiqsut
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1295
69
1420
102
Hide CD5
hide-CD5
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1295
109
1423
142
Hide Cisco
hide-cisco
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
1011
185
1343
230
BoundsFile
BoundsFile
"data/ascBounds/CharDolly10Y.asc" "data/ascBounds/CharDolly12M.asc" "data/ascBounds/Cisco10Y.asc" "data/ascBounds/Cisco12M.asc" "data/ascBounds/MooseBounds10Y.asc" "data/ascBounds/MooseBounds12M.asc" "data/ascBounds/whitefish12m.asc" "data/ascBounds/whitefish10Y.asc"
4

BUTTON
1012
238
1140
271
Show Bounds
display-bounds
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1144
238
1222
271
Clear
cd
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
983
65
1155
98
Show Moose Nodes
display-protograph
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
983
110
1157
143
Hide Moose Nodes
hide-protograph
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
162
56
225
89
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
800
18
833
168
elevation-limit
elevation-limit
0
1000
237.0
1
1
NIL
VERTICAL

SLIDER
799
256
989
289
caribou-amt
caribou-amt
0
50000
21000.0
1000
1
NIL
HORIZONTAL

SLIDER
1000
335
1172
368
moose-amt
moose-amt
0
150
0.0
1
1
NIL
HORIZONTAL

SLIDER
800
293
990
326
caribou-group-amt
caribou-group-amt
0
200
30.0
1
1
NIL
HORIZONTAL

SLIDER
801
334
991
367
caribou-radius
caribou-radius
0
12
3.0
0.5
1
NIL
HORIZONTAL

BUTTON
76
406
230
439
Show Vegetation
display-vegetation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
31
478
265
511
set-centroid-attraction
set-centroid-attraction
0.01
1
0.06
0.01
1
NIL
HORIZONTAL

INPUTBOX
1271
282
1340
342
caribou-util-type-2
0.25
1
0
Number

INPUTBOX
1344
282
1414
342
caribou-util-type-3
0.5
1
0
Number

INPUTBOX
1418
282
1488
342
caribou-util-type-4
0.66
1
0
Number

INPUTBOX
1271
378
1341
438
caribou-veg-factor
1.0
1
0
Number

INPUTBOX
1345
378
1415
438
caribou-rough-factor
-5.0
1
0
Number

TEXTBOX
1371
262
1547
292
Caribou Vegetation Values
12
53.0
1

TEXTBOX
1386
357
1557
387
Caribou Utility Factors
12
13.0
1

INPUTBOX
1420
377
1490
437
caribou-insect-factor
0.8
1
0
Number

INPUTBOX
1494
377
1564
437
caribou-modifier-factor
-1.0
1
0
Number

SLIDER
33
516
267
549
caribou-modify-amt
caribou-modify-amt
0
3
0.5
0.1
1
NIL
HORIZONTAL

BUTTON
36
567
201
601
Random Centroids
ask caribou [set current-centroid (random 5 + 1)]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
209
566
373
600
Change Attraction
ask caribou [set centroid-attraction set-centroid-attraction]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
384
564
508
598
Display Pens
ask caribou\n[\nlet a random 5\nlet b random 5\nifelse (a = b) [pen-down] [pen-up]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
649
566
752
600
Kill Moose
ask moose [die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
808
193
956
227
Darken Patches
ask patches\n[\n    set pcolor pcolor - 1\n]
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

INPUTBOX
734
662
805
722
decay-rate
2.0E-4
1
0
Number

INPUTBOX
808
662
880
722
caribou-reutility
0.01
1
0
Number

SWITCH
796
431
998
464
show-caribou-utility?
show-caribou-utility?
1
1
-1000

INPUTBOX
45
662
104
722
caribou-max-wetness
0.8
1
0
Number

INPUTBOX
107
662
168
722
caribou-max-elevation
700.0
1
0
Number

TEXTBOX
48
646
113
664
Wetness
12
0.0
1

TEXTBOX
110
646
169
664
Elevation
12
0.0
1

INPUTBOX
474
659
546
719
diffuse-amt
0.0
1
0
Number

INPUTBOX
552
660
618
720
elevation-scale
0.0
1
0
Number

INPUTBOX
1492
282
1564
342
caribou-util-type-5
0.75
1
0
Number

INPUTBOX
1567
282
1640
342
caribou-util-type-9
0.75
1
0
Number

INPUTBOX
1567
377
1638
437
caribou-deflection-factor
1.0
1
0
Number

INPUTBOX
267
661
331
721
moose-max-elevation
700.0
1
0
Number

INPUTBOX
200
660
264
720
moose-max-wetness
0.8
1
0
Number

INPUTBOX
1273
489
1343
549
moose-util-type-2
0.25
1
0
Number

INPUTBOX
1346
489
1418
549
moose-util-type-3
0.66
1
0
Number

INPUTBOX
1420
489
1492
549
moose-util-type-4
0.5
1
0
Number

INPUTBOX
1495
489
1569
549
moose-util-type-5
0.66
1
0
Number

INPUTBOX
1572
489
1642
549
moose-util-type-9
0.25
1
0
Number

INPUTBOX
1274
585
1345
645
moose-veg-factor
1.0
1
0
Number

INPUTBOX
1347
585
1419
645
moose-rough-factor
-5.0
1
0
Number

INPUTBOX
1421
585
1494
645
moose-insect-factor
0.5
1
0
Number

INPUTBOX
1497
585
1568
645
moose-deflection-factor
1.0
1
0
Number

MONITOR
859
86
916
131
Day
day
1
1
11

SWITCH
797
466
1000
499
show-moose-utility?
show-moose-utility?
1
1
-1000

TEXTBOX
1380
467
1569
497
Moose Vegetation Values
12
0.0
1

TEXTBOX
1359
561
1509
579
Moose Utility Factors
12
0.0
1

TEXTBOX
830
410
980
428
Show Utility Values
12
0.0
1

TEXTBOX
819
235
969
253
Caribou Spawn Values
12
0.0
1

TEXTBOX
1094
163
1244
181
Show Harvest Bounds
12
0.0
1

TEXTBOX
1033
314
1183
332
Moose Population
12
0.0
1

TEXTBOX
205
645
266
663
Wetness
12
0.0
1

TEXTBOX
270
646
340
664
Elevation
12
0.0
1

TEXTBOX
238
622
388
641
Moose
16
0.0
1

TEXTBOX
72
622
222
641
Caribou
16
0.0
1

TEXTBOX
490
632
640
650
?? Insect Vals ??
12
0.0
1

TEXTBOX
642
540
792
558
Temp Commands
12
0.0
1

TEXTBOX
998
48
1148
66
Harvest Graph Nodes\n
12
0.0
1

TEXTBOX
840
16
990
34
Spawn Elevation Limit
12
0.0
1

MONITOR
858
36
915
81
Hour
hour
17
1
11

INPUTBOX
39
749
203
809
centroid-attraction-max
0.55
1
0
Number

INPUTBOX
40
814
201
874
centroid-attraction-min
0.04
1
0
Number

INPUTBOX
40
879
201
939
caribou-cent-dist-cutoff
20.0
1
0
Number

INPUTBOX
41
940
200
1000
caribou-util-cutoff
0.2
1
0
Number

INPUTBOX
1047
660
1123
720
learn-rate
0.01
1
0
Number

INPUTBOX
1046
592
1127
652
mutate-amt
0.03
1
0
Number

SWITCH
1045
554
1180
587
is-training?
is-training?
1
1
-1000

MONITOR
859
135
916
184
Year
year
0
1
12

SWITCH
797
505
956
538
caribouPopMod?
caribouPopMod?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
