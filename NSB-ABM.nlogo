;Main code for the ABM

;Zip file w/ model and data:
;https://drive.google.com/a/alaska.edu/file/d/0B6Qg-B9DYEuKVE5EQldZMjUtRlE/view?usp=sharing


extensions [ gis array matrix table csv profiler]

__includes["nls-modules/insect.nls" "nls-modules/precip.nls" "nls-modules/NDVI.nls" "nls-modules/caribouPop.nls"
  "nls-modules/caribou.nls" "nls-modules/moose.nls" "nls-modules/hunters.nls"
  "nls-modules/fcm.nls" "nls-modules/patch-list.nls" "nls-modules/utility-functions.nls" "nls-modules/display.nls" "nls-modules/connectivityCorrection.nls" "nls-modules/vegetation-rank.nls"
  "nls-modules/migration-grids.nls" "nls-modules/migration-centroids.nls" "nls-modules/caribou-calibration.nls" "nls-modules/kde-sample.nls" ]


breed [moose a-moose]
breed [caribou a-caribou]
breed [cisco a-cisco]
breed [char a-char]
breed [whitefish a-whitefish]
breed [centroids centroid]
breed [grids grid]
breed [deflectors deflector]
breed [mem-markers mem-mark]
breed [hunters hunter]
breed [caribou-harvests caribou-harvest] ;centroids for caribou harvest
directed-link-breed [ cent-links cent-link ]

globals
[
  file-output-prepend

  npGridId
  npGridQual
  pGridId
  pGridQual

  seed
  caribouVarCal ;;list containing values of caribou related variables that need to be calibrated.

  patches-oil-bounds
  patches-roads
  patches-pipeline

  np-centroid-layer-152
  np-centroid-layer-166
  np-centroid-layer-180
  np-centroid-layer-194
  np-centroid-layer-208
  np-centroid-layer-222
  np-centroid-layer-236
  np-centroid-layer-250
  p-centroid-layer-152

  ;GIS DATA
  np-centroid-network
  p-centroid-network
  cent-day-list ;for recording list of days where the centroids need to be reassigned in the simulation
  avg-sim-time ;for reporting the average amount of time it takes to simulate each year.

  caribou-fcm-perception-weights-list
  caribou-fcm-adja-list
  caribou-fcm-agentnum-list
  caribou-fcm-success-list

  patch-roughness-dataset
  patch-wetness-dataset
  patch-streams-dataset
  patch-elevation-dataset
  patch-ocean-dataset
  patch-whitefish-dataset
  patch-caribou-harvest-dataset

  ;Boundaries for Development
  patch-boundary-beartooth
  patch-boundary-beecheypoint
  patch-boundary-colvilleriver
  patch-boundary-dewline
  patch-boundary-duckisland
  patch-boundary-greatermoosestooth
  patch-boundary-kuparukriver
  patch-boundary-liberty
  patch-boundary-milnepoint
  patch-boundary-nikaitchuq
  patch-boundary-northstar
  patch-boundary-oooguruk
  patch-boundary-pikka
  patch-boundary-placer
  patch-boundary-prudhoebay
  patch-boundary-smiluveach
  patch-pipes_layer
  patch-roads_layer

  ;globals for the NDVI.nls module.
  ndvi-dataset
  vegetation-ndvi-list
  ;ndvi-matrix
  ndvi-max

  vegetation-CP-list
  vegetation-CNP-list
  vegetation-PC-list
  vegetation-MH-list
  vegetation-ML-list
  vegetation-OH-list
  vegetation-OL-list
  vegetation-LS-list

  veg-selection-season
  ndvi-all-max

  season ;set to [0-3] corresponding to current season currently set to summer always

  patch-vegetation-dataset
  max-roughness

  ;Globals Precipitation
  precipitation-dataset
  	precipitation-data-list
  	precipitation-max
  precipitation-matrix-number

  ;;Bounds Data
  boundsTestData

  current-season

  ;Reward Online Learning (Q)
  a-net-w1
  a-net-w2
  a-net-wout


  adjacency-matrix

  ;Caribou-Bank
  caribou-bank-may22
  caribou-bank-jul16
  caribou-bank-sep16
  caribou-bank-nov16
  caribou-bank-jan1
  caribou-bank-mar1

  ;Time Info
  year
  day
  hour

  ;;FCM
  base-fcm-caribou
  best-caribou-val
  fcm-adja-base
  caribou-fcm-perception-weights-base


  ;PatchList for movement decisions
  patch-coord-x
  patch-coord-y
  patch-list-exists
  patch-list-utility
  patch-array-iterator
  ;;WORK AROUND NUMBERS;; These numbers are used to work around limitations with the
  ;    NetLogo language

  caribou-var-E-diff
  caribou-bio-list
  caribou-pop
  caribou/agent
  r-caribou

  ;;magic centroid number - A hack to allow comparison with centriod number
  magic-centroid



  ;;;;; HENRI'S GLOBALS ;;;;;
  mosquito-sigma
  oestrid-sigma
  mosquito-means-list
  oestrid-means-list
  mosquito-sigma-list
  oestrid-sigma-list
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
  insect-season
  hunter-harvest-total
  hunter-trip-control
  hunter-fcm-list
  hunter-streams-restriction
  caribou-harvest-selection-list
  caribou-harvest-fRanks-list
  caribou-harvest-probability-list
]

patches-own
[
  patch-id
  river-set
  river-id
  np-network-id
  p-network-id
  cent-dist
  gnpid
  gpid
  np-grid-id
  p-grid-id
  grid-util-non-para
  grid-util-para
  cent-util-list-non-para
  cent-util-list-para
  npid
  pid
  cent-util-para
  cent-util-non-para
  wetness
  streams
  ocean
  roughness
  elevation
  boundsTest
  vegetation-type
  ndvi-quality
  whitefish? ;for whether or not a patch has been used for broad whitefish harvesting in last 10 yr. (Braund report)
  patch-caribou-harvest

  ;Patches Precipitation.nls
  precipitation-amt
  prec-paint



  ;;Utility Values
  ;caribou
  connected? ;boolean for whether or not patches are connected by a stream. Setting to be true for all patches with streams > than 1/2 mean [streams] of patches.
  caribou-utility-max
  caribou-utility
  caribou-utility-para
  caribou-utility-non-para
  caribou-modifier ;modified based on caribou vists. Add decay?
  patch-deflection-oil
  patch-deflection-roads
  patch-deflection-pipeline
  patch-deflection-temp


  ;moose
  moose-utility-max
  moose-utility
  ;all
  deflection

  vegParRank ;vegetation ranking of patch for pregnant caribou
  vegNonParRank ;vegetation ranking of patch for non-pregnant caribou
                ;;;;; HENRI PATCH VALUES ;;;;;
  vegetation-beta

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

  patch-historic-utility-caribou
]

caribou-harvests-own
[
  frequency-rank
]
centroids-own
[
  avg-insect
  veg-quality
  radius
  cid
  category

]

grids-own
[
  grid-id
  np-qual-id
  p-qual-id
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


mem-markers-own
[
  caribou-id
]

cent-links-own
[
  link-weight
]

;wraps to other setup functions
to setup
  set file-output-prepend ""
  clear-all
  set seed -2147483648 + random-num (2147483648 * 2)
  random-seed seed
  set time-of-year 0
  set max-roughness 442.442
  set hour 0
  set day 152
  set year 0
  reset-caribou-banks

  set cent-day-list [ ]
  ask patches
  [ set cent-util-list-non-para [ ]
    set cent-util-list-para [ ]
    set np-grid-id 0
    set p-grid-id 0 ]

  let counter 1
  let xc -64 let yc 64 while [ yc >= -64]  [ ask patch xc yc [set patch-id counter] set counter counter + 1 set xc xc + 1 if xc >= 65 [ set yc yc - 1 set xc -64 ] ]

  setup-cent-layers
  setup-grid-layers

  set np-centroid-network np-centroid-layer-152
  set p-centroid-network p-centroid-layer-152

  centroid-read day
  grid-read day

  set season 1
  setup-deflectors
  set ndvi-all-max 247
  reset-timer
  set avg-sim-time [ ]
  ;this must be called to apply first deflector values
  go-deflectors


  set caribou-bank-may22 [8 4 2 2]
  set caribou-bank-jul16 [8 4 2 2]
  set caribou-bank-sep16 [8 4 2 2]
  set caribou-bank-nov16 [8 4 2 2]
  set caribou-bank-jan1 [8 4 2 2]
  set caribou-bank-mar1 [8 4 2 2]


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
  setup-caribou
  setup-caribou-q

  setup-patch-list
  setup-insect
  set-precipitation-data-list
  go-precipitation
  if(is-random?)
  [
    caribou-random-fcm
  ]

  set caribou-fcm-adja-list [fcm-adja] of caribou
  go-veg-ranking
  set-streams

  ask patches
  [ set grid-util-non-para 0
    set grid-util-para 0 ]

  test-flow

  if export-logger-data?
  [
    setup-logger-data
  ]

  setup-caribou-var-cal
  if exportCaribouData? [
    setup-caribou-state-data
    setup-caribou-fcm-data
  ]


  set hunter-streams-restriction (0.025 * (max [streams] of patches))
  set hunter-trip-control 123
  if use-hunters? [
    setup-caribou-harvests
    build-caribou-harvest-lists
    build-caribou-harvest-prob-list
    initialize-FCM-hunters
    setup-hunter-nls
  ]


  setup-caribou-kde-file
  setup-hunter-kde-file



  reset-ticks
  scenario-controller

end


to setup-caribou-harvests
  ask patches
  [
    if (pxcor mod 2 = 0) and (pycor mod 2 = 0)
    [
      sprout-caribou-harvests 1 [set frequency-rank [patch-caribou-harvest] of patch-here]
    ]
  ]

  ask caribou-harvests
  [
    if (frequency-rank = 21)
    [
      die
    ]
    set color scale-color red frequency-rank 0 20
    set size 1
    set shape "circle"
  ]

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
      set size 0
    ]
    ;show idCounter
    set idCounter (idCounter + 1)
  ]


  file-close

end


to setup-deflectors
  ;;create deflectors according to development sites: CD5 and Nuiqsut.
  ;;create Nuiqsut
  ;;Using Nuiqsut bounds on Google maps, coordinate center sits in a 3 mi x 3 mi (4828.032 m x 4828.032 m) square
  if Nuiqsut? [
    create-deflectors 1
    [
      let patch-x 0.38689265536723383
      let patch-y 4.621468926553675
      set xcor patch-x
      set ycor patch-y
      set shape "dot"
      set label "NUIQSUT"
      set color red
      ;;set an area over which we consider to be 'developed'. Caribou agents should be able to sense this
      ;;within 1 km buffer range if following similar setup as the Albert caribou ABM paper.
      set area-outer (4828.032 / 2195.35)
      set area-inner 0
      set deflect-amt 1
      set has-applied false
      ht
    ]
  ]

  if CD5? [
    create-deflectors 1
    [
      let patch-x -2.2409039548022633
      let patch-y 8.624632768361579
      set xcor patch-x
      set ycor patch-y
      set shape "dot"
      set label "CD5"
      set color red
      ;;development bounds of CD5 still need to be selected.
      set area-outer (3000 / 2195.35)
      set area-inner 0
      set deflect-amt 1
      set has-applied false
      ht
    ]
  ]

end

to profile-test
  let profileOut "profiler-dat.txt"
  profiler:reset
  profiler:start

  setup
  while [ year != 2 ] [ go ]

  profiler:stop
  print profiler:report
  file-open profileOut
  file-print profiler:report
  file-close-all
end


to scenario-controller
  if scenario != "none" [
    ;; set variables common to all scenarios
    set display-plots? false
    set dynamic-display? false
    set show-caribou-utility-para? false
    set show-caribou-utility-non-para? false
    set show-moose-utility? false
    set display-centroids? false
    set display-grids? false
    set Nuiqsut? true
    set CD5? true
    set BoundsFile "data/development-regions/pipes_layer.asc"

    ;; caribou default variables:
    ;; no recalibration of related environment vars
    ;; import pre-existing FCMs and env vars
    ;; allow evolution of FCM to occur
    set caribouPopMod? false
    set caribou-amt 2500
    set caribou-group-amt 50
    set caribou-radius 1.5
    set caribou-para 0.71
    set elevation-limit 221
    set use-q false
    set Q-rate 0.001
    set Q-Gamma 0.999
    set debug-fcm? false
    set prob-var-recombination .33
    set import-caribou-fcm? true
    set import-caribou-var? true
    set is-random? false
    set is-training? true
    set randomCaribouVarStart? false
    set calibrateCaribouVar? false
    set exportCaribouData? true
    set mutation-method "fuzzy-logic"
    set caribou-recomb-prob 0.2
    set caribou-mutate-prob 0.15
    set caribou-recombine? true
    set caribou-mutate? true
    set export-centroids? false
    set set-centroid-attraction 0.1
    set caribou-max-wetness 0.8
    set caribou-max-elevation 700
    set caribou-modify-amt 1
    ;; end default caribou vars

    set moose-amt 0

    ;; default hunter vars:
    ;; no hunter fcm import
    ;; hunter fcms are evolving
    set hunter-recomb-prob 0.2
    set hunter-mutate-prob 0.15
    set hunter-mutate? true
    set hunter-recombine? true
    ;; remove comment later after building hunter fcms up -
    set random-hunter-fcm? true
    ;; set random-hunter-fcm? false
    set caribou-harvest-high-constant 0.6
    set caribou-harvest-low-constant 0.4
    set local-search-radius 3
    set hunter-harvest-goal 1
    set hunter-centroid-selection 15
    set trip-length-max 112
    set hunter-vision 2
    set hunter-population 35
    set use-hunters? true
    set export-hunter-data? true
    set hunter-training? true
    set prey-close-constant .4
    set prey-far-constant .6
    set trip-long-constant .4
    set trip-short-constant .6
    set boat-hike-long-constant .4
    set boat-hike-short-constant .6
    set hunter-density-low-constant .4
    set hunter-density-high-constant .6
    set deflect-pipeline? false
    set deflect-oil? false
    set deflect-roads? false
    set use-hunters? true
    ;; end default hunter vars

    if scenario = "control-w-hunters-lo" [
      ;; evolve agents for 1000 years.
      	  set use-high-res-ndvi? false
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      ;; run scenario and collect results for 100 years.
      while [ year != 100 ] [
        go
      ]
    ] ;; end control with hunters if

    if scenario = "control-no-hunters-lo" [
      ;; make sure variable settings are appropriately set.
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false
      set use-high-res-ndvi? false

      ;; evolve agents for 1000 years.
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      ;; run scenario and collect results for 100 years.
      while [ year != 100 ] [
        go
      ]
    ] ;; end control no hunters if

    if scenario = "obd-w-hunters-lo" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      	  set use-high-res-ndvi? false
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ] ;; end obd w hunters if

    if scenario = "obd-no-hunters-lo" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false
      set use-high-res-ndvi? false

      while [ year != 1000 ]
      [
        go
      ]

      scenario-var-reset

      while [ year != 100 ]
      [
        go
      ]
    ] ;; end obd-no-hunters if

    if scenario = "veg-later-shift-w-hunters-lo" [
      ;; add in matrix shift...
      set use-high-res-ndvi? false
      set-later-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]

    ] ;; end veg-shift-w-hunters if

    if scenario = "veg-later-shift-no-hunters-lo" [
      ;; add in matrix shift...
      set use-high-res-ndvi? false
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false
      set-later-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ] ;; end veg-shift-no-hunters if
    if scenario = "veg-early-shift-w-hunters-lo" [
      ;; add in matrix shift...
      	  set use-high-res-ndvi? false
      set-early-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]

    ] ;; end veg-shift-w-hunters if

    if scenario = "veg-early-shift-no-hunters-lo" [
      ;; add in matrix shift...
      set use-high-res-ndvi? false
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false
      set-early-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ] ;; end veg-shift-no-hunters if
    if scenario = "caribou-evolution-lo" [
      	  set use-high-res-ndvi? false
      set calibrateCaribouVar? true
      set randomCaribouVarStart? true
      set import-caribou-var? false
      set is-random? true
      set Nuiqsut? false
      set CD5? false

      while [ year <= 2500 ] [ go ] ;; user will have to use space bar interrupt in file to stop evolution before end point.

    ] ;; end caribou-evolution if

    if scenario = "hunter-evolution-lo" [
      set use-high-res-ndvi? false
      set random-hunter-fcm? true
      while [ year <= 1 ] [ go ] ;; user will have to use space bar interrupt in file to stop evolution before end point.
    ] ;; end hunter-evolution if

    ;;;HIGH RESOLUTION NDVI SCENARIOS
    if scenario = "control-w-hunters-hi" [
      ;; evolve agents for 1000 years.
      	  set use-high-res-ndvi? true
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      ;; run scenario and collect results for 100 years.
      while [ year != 100 ] [
        go
      ]
    ] ;; end control with hunters if

    if scenario = "control-no-hunters-hi" [
      ;; make sure variable settings are appropriately set.
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false

      set use-high-res-ndvi? true

      ;; evolve agents for 1000 years.
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      ;; run scenario and collect results for 100 years.
      while [ year != 100 ] [
        go
      ]
    ] ;; end control no hunters if

    if scenario = "obd-w-hunters-hi" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      	  set use-high-res-ndvi? true
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ] ;; end obd w hunters if

    if scenario = "obd-no-hunters-hi" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false

      set use-high-res-ndvi? true

      while [ year != 1000 ]
      [
        go
      ]

      scenario-var-reset

      while [ year != 100 ]
      [
        go
      ]
    ] ;; end obd-no-hunters if

    if scenario = "veg-later-shift-w-hunters-hi" [
      ;; add in matrix shift...
      	  set use-high-res-ndvi? true
      set-later-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]

    ] ;; end veg-shift-w-hunters if

    if scenario = "veg-later-shift-no-hunters-hi" [
      ;; add in matrix shift...
      set use-high-res-ndvi? true
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false
      set-later-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ] ;; end veg-shift-no-hunters if
    if scenario = "veg-early-shift-w-hunters-hi" [
      ;; add in matrix shift...
      	  set use-high-res-ndvi? true
      set-early-shifted-ndvi-data-list

      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]

    ] ;; end veg-shift-w-hunters if

    if scenario = "veg-early-shift-no-hunters-hi" [
      ;; add in matrix shift...
      set use-high-res-ndvi? true
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false

      set-early-shifted-ndvi-data-list
      while [ year != 1000 ] [
        go
      ]

      scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ] ;; end veg-shift-no-hunters if
    if scenario = "caribou-evolution-hi" [
      	  set use-high-res-ndvi? true
      set calibrateCaribouVar? true
      set randomCaribouVarStart? true
      set import-caribou-var? false
      set is-random? true
      set Nuiqsut? false
      set CD5? false

      while [ year <= 2500 ] [ go ] ;; user will have to use space bar interrupt in file to stop evolution before end point.

    ] ;; end caribou-evolution if

    if scenario = "hunter-evolution-hi" [
      set use-high-res-ndvi? true
      set random-hunter-fcm? true
      while [ year <= 1 ] [ go ] ;; user will have to use space bar interrupt in file to stop evolution before end point.
    ] ;; end hunter-evolution if

    ;combined scenarios
    	if scenario = "combined-early-ndvi-w-hunters-hi" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-early-shifted-ndvi-data-list
      set use-high-res-ndvi? true
      set use-hunters? true
      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ]
    	if scenario = "combined-early-ndvi-no-hunters-hi" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-early-shifted-ndvi-data-list
      set use-high-res-ndvi? true
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false

      while [ year != 1000 ] [
        go
      ]
    	  ]
    	  	if scenario = "combined-late-ndvi-w-hunters-hi" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-later-shifted-ndvi-data-list
      set use-high-res-ndvi? true
      set use-hunters? true
      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ]
    	if scenario = "combined-late-ndvi-no-hunters-hi" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-later-shifted-ndvi-data-list
      set use-high-res-ndvi? true
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false

      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    	  ]
    	if scenario = "combined-early-ndvi-w-hunters-lo" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-early-shifted-ndvi-data-list
      set use-high-res-ndvi? false
      set use-hunters? true
      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ]
    	if scenario = "combined-early-ndvi-no-hunters-lo" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-early-shifted-ndvi-data-list
      set use-high-res-ndvi? false
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false
      set export-hunter-data? false
      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    	  ]

    	if scenario = "combined-late-ndvi-w-hunters-lo" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-later-shifted-ndvi-data-list
      set use-high-res-ndvi? false
      set use-hunters? true

      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ]

    	if scenario = "combined-late-ndvi-no-hunters-lo" [
      set deflect-pipeline? true
      set deflect-oil? true
      set deflect-roads? true
      set-later-shifted-ndvi-data-list
      set use-high-res-ndvi? false
      set use-hunters? false
      set hunter-mutate? false
      set hunter-recombine? false
      set hunter-training? false

      while [ year != 1000 ] [
        go
      ]
      	
      	        scenario-var-reset

      while [ year != 100 ] [
        go
      ]
    ]

  ] ;; end outer if
end

to scenario-var-reset
  set year 0
  set collect-kde? true
  set is-training? false
  set hunter-training? false
end

;Go, wraps to other go's
to go
  ; set day (ticks mod 365)
  set hour hour + 1.5
  if(hour = 24)
  [
    reset-caribou-banks
    set hour 0
    set day (day + 1)
    go-ndvi
    if day > 151 and day < 258
    [
      go-veg-ranking
    ]
    if(day >= 258) ;old value is 365
    [

      if caribouPopMod? = true
      [ go-caribou-pop ]

      if calibrateCaribouVar? [ go-caribou-var-cal ]

      if(is-training?) [ update-caribou-fcm ]


      if(export-hunter-data?) [ export-hunter-data 1 ];export hutner data at year end
      set hunter-harvest-total 0
      if(hunter-training?) [ update-hunter-fcms ]

      if exportCaribouData? [ export-fcm-data ];;at end of year, export FCMs, success thereof, and stateflux (just export individual state flux variables.)

      set year year + 1
      set day 152

      set avg-sim-time lput timer avg-sim-time
      reset-timer
    ]



    if day = 152 [ go-insect ]
    if day = 166 [ go-insect ]
    if day = 181 [ go-insect ]
    if day = 196 [ go-insect ]
    if day = 212 [ go-insect ]
    if day = 227 [ go-insect ]

    if (day - 12) mod 14 = 0
    [
      centroid-read day
      grid-read day

      ask caribou [ reset-caribou-centroids ]

    ]

    if export-centroids? [ centroid-export ]
    swap-centroid-layers

    go-precipitation

  ]

  go-deflectors
  ;go-insect
  go-moose
  ifelse(use-q = true)
  [
    go-caribou-q
  ]
  [
    go-caribou
  ]

  update-caribou-utility
  update-para-utility
  update-non-para-utility
  update-moose-utility
  if dynamic-display? [ go-dynamic-display ]

  if exportCaribouData?[ export-caribou-state-data ]

  if export-logger-data?
  [
    export-logger-data
  ]

  if use-hunters? [
    go-hunters-nls
  ]

  collect-caribou-coordinates
  collect-hunter-coordinates
  tick
end

to setup-logger-data
  let hunter-logger-ex "hunter-logger.txt"
  let caribou-logger-ex "caribou-logger.txt"

  if file-exists? hunter-logger-ex [ file-delete hunter-logger-ex ]
  if file-exists? caribou-logger-ex [ file-delete caribou-logger-ex ]

  file-open hunter-logger-ex
  file-write "scenario"
  file-write "agent"
  file-write "FCM"
  file-write "input-matrix"
  file-write "sensory"
  file-write "states"
  file-close

  file-open caribou-logger-ex
  file-write "scenario"
  file-write "agent"
  file-write "FCM"
  file-write "input-matrix"
  file-write "sensory"
  file-write "states"
  file-close
end

to export-logger-data
  file-open "hunter-logger.txt"
  ask hunters
  [
    file-print ""
    file-write word scenario ","
    file-write word ([who] of self) ","
    file-write word matrix:to-row-list hunter-fcm-matrix ","
    file-write word matrix:to-row-list hunter-input-matrix ","
    file-write word matrix:to-row-list hunter-fcm-sensory ","
    file-write word matrix:to-row-list previous-activations ","
  ]
  file-close

  file-open "caribou-logger.txt"
  ask caribou
  [
    file-print ""
    file-write word scenario ","
    file-write word ([who] of self) ","
    file-write word matrix:to-row-list fcm-adja ","
    file-write word matrix:to-row-list caribou-fcm-perception-weights ","
    file-write word matrix:to-row-list caribou-fcm-perceptions ","
    file-write word matrix:to-row-list caribou-prev-fcm-node-states ","
  ]
  file-close
end
to setup-caribou-state-data
  let file-ex "caribou-state-flux-bioE-"
  set file-ex word file-ex seed
  set file-ex word file-ex ".txt"

  if file-exists? file-ex [ file-delete file-ex ]

  file-open file-ex

  file-write "ticks"
  file-write "state 0"
  file-write "state 1"
  file-write "state 2"
  file-write "state 3"
  file-write "state 4"
  file-write "bioenergy success"
  file-close

end

to export-caribou-state-data
  let file-ex "caribou-state-flux-bioE-"
  set file-ex word file-ex seed
  set file-ex word file-ex ".txt"

  file-open file-ex
  file-print ""
  file-write ticks
  file-write count caribou with [state = 0]
  file-write count caribou with [state = 1]
  file-write count caribou with [state = 2]
  file-write count caribou with [state = 3]
  file-write count caribou with [state = 4]
  file-write mean [ bioenergy-success ] of caribou
  file-close
end

to setup-caribou-fcm-data
  let file-ex "caribou-fcms-agentnum-success-"
  set file-ex word file-ex seed
  set file-ex word file-ex ".txt"

  if file-exists? file-ex [ file-delete file-ex ]

  file-open file-ex
  file-write "year,"
  file-write "fcm agent useage,"
  file-write "fcm success,"
  file-write "caribou fcm-adja matrix,"
  file-write "caribou fcm-perception-weights matrix"
  file-close
end

to export-fcm-data
  ;;dump all pertinent data every year for variable calibration.
  ;set caribou-fcm-adja-list [fcm-adja] of caribou

  let file-ex "caribou-fcms-agentnum-success-"
  set file-ex word file-ex seed
  set file-ex word file-ex ".txt"

  file-open file-ex

  let x length caribou-fcm-adja-list
  let y 0
  while [ y < x ] [
    file-print ""
    file-write word year ","
    file-write word (item y caribou-fcm-agentnum-list) ","
    file-write word (item y caribou-fcm-success-list) ","
    file-write matrix:to-row-list (item y caribou-fcm-adja-list)
    file-write matrix:to-row-list (item y caribou-fcm-perception-weights-list)
    set y y + 1
  ]

  file-close
end


to reset-caribou-centroids
  ifelse day > 151 and day < 166 and caribou-class = 2
    [ set current-centroid min-one-of patches with [pid > 0] [distance myself]
      set last-centroid patch -64 64 ];current-centroid ]
  [ set current-centroid min-one-of patches with [npid > 0] [distance myself]
    set last-centroid patch -64 64 ];current-centroid ] ]
                                    ;starting grid is closest grid
  ifelse day > 151 and day < 166 and caribou-class = 2
    [ set current-grid min-one-of grids with [p-qual-id > 0] [distance myself]
      set current-grid [who] of current-grid
      set last-grid 0 ]
  [ set current-grid min-one-of grids with [np-qual-id > 0] [distance myself]
    set current-grid [who] of current-grid
    set last-grid 0 ]
end

to reset-caribou-banks
  ask caribou
  [
    set bank-rest 8
    set bank-intra 5
    set bank-inter 2
    set bank-migrate 1
  ]
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
  if (show-caribou-utility-para?)
  [
    display-caribou-utility-para
  ]
  if (show-caribou-utility-non-para?)
  [
    display-caribou-utility-non-para
  ]

  if (show-moose-utility?)
  [
    display-moose-utility
  ]
end




to setup-terrain-layers

  ;set ndvi-matrix 0 ;initializing to May 1 NDVI layer. Shouldnt be used ofc until May 1 is reached in the model, though..
  ;need to implement timing for NDVI layer switching. Day 121 = May 1 in the simulation, and day 263 = Oct. 20
  ;(day 1 = Jan. 1)
  ask patches [ set ndvi-quality 0 ]
  set-ndvi-data-list ;setting up the NDVI list
  if day >= 151 [ set day 151 go-ndvi set day 152 ] ;bug fix that maintains logic behind NDVI load in procedures.
  set patch-wetness-dataset gis:load-dataset "data/patches/PatchWetness.asc"
  set patch-streams-dataset gis:load-dataset "data/patches/PatchStreams.asc"
  set patch-elevation-dataset gis:load-dataset "data/patches/PatchElevation.asc"
  set patch-ocean-dataset gis:load-dataset "data/patches/PatchOcean.asc"
  set patch-roughness-dataset gis:load-dataset "data/patches/PatchRoughness.asc"
  set patch-vegetation-dataset gis:load-dataset "data/patches/NorthSlopeVegetation.asc"
  ;set patch-whitefish-dataset gis:load-dataset "data/ascBounds/whitefish10Y.asc"
  set patch-caribou-harvest-dataset gis:load-dataset "data/ascBounds/caribou12m-scale.asc"

  ;development regions
  set patch-boundary-beartooth gis:load-dataset "data/development-regions/sm_Bear_Tooth.asc"
  set patch-boundary-beecheypoint gis:load-dataset "data/development-regions/sm_Beechey_Point.asc"
  set patch-boundary-colvilleriver gis:load-dataset "data/development-regions/sm_Colville_River.asc"
  set patch-boundary-dewline gis:load-dataset "data/development-regions/sm_Dewline.asc"
  set patch-boundary-duckisland gis:load-dataset "data/development-regions/sm_Duck_Island.asc"
  set patch-boundary-greatermoosestooth gis:load-dataset "data/development-regions/sm_Greater_Mooses_Tooth.asc"
  set patch-boundary-kuparukriver gis:load-dataset "data/development-regions/sm_Kuparuk_River.asc"
  set patch-boundary-liberty gis:load-dataset "data/development-regions/sm_Liberty.asc"
  set patch-boundary-milnepoint gis:load-dataset "data/development-regions/sm_Milne_Point.asc"
  set patch-boundary-nikaitchuq gis:load-dataset "data/development-regions/sm_Nikaitchuq.asc"
  set patch-boundary-northstar gis:load-dataset "data/development-regions/sm_Northstar.asc"
  set patch-boundary-oooguruk gis:load-dataset "data/development-regions/sm_Oooguruk.asc"
  set patch-boundary-pikka gis:load-dataset "data/development-regions/sm_Pikka.asc"
  set patch-boundary-placer gis:load-dataset "data/development-regions/sm_Placer.asc"
  set patch-boundary-prudhoebay gis:load-dataset "data/development-regions/sm_Prudhoe_Bay.asc"
  set patch-boundary-smiluveach gis:load-dataset "data/development-regions/sm_S_Miluveach.asc"
  set patch-roads_layer gis:load-dataset "data/development-regions/roads_layer.asc"
  set patch-pipes_layer gis:load-dataset "data/development-regions/pipes_layer.asc"


  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-wetness-dataset))

  gis:apply-raster patch-wetness-dataset wetness
  gis:apply-raster patch-roughness-dataset roughness
  gis:apply-raster patch-streams-dataset streams
  gis:apply-raster patch-elevation-dataset elevation
  gis:apply-raster patch-ocean-dataset ocean
  gis:apply-raster patch-vegetation-dataset vegetation-type

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-boundary-beartooth))
  if(deflect-oil?)
  [
    gis:apply-raster patch-boundary-beartooth patch-deflection-temp
    ;Union operation between all datasets, direct application of rasters will overwrite previous values.
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]

    ;do the same for the rest of datasets
    gis:apply-raster patch-boundary-beartooth patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-beecheypoint patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-colvilleriver patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-dewline patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-duckisland patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-greatermoosestooth patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-kuparukriver patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-liberty patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-milnepoint patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-nikaitchuq patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-northstar patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-oooguruk patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-pikka patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-placer patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-prudhoebay patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]
    gis:apply-raster patch-boundary-smiluveach patch-deflection-temp
    ask patches with [patch-deflection-temp > 0] [set patch-deflection-oil patch-deflection-temp]

    set patches-oil-bounds patches with [patch-deflection-oil > 0]

  ]

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-roads_layer))
  if(deflect-roads?)
  [
    gis:apply-raster patch-roads_layer patch-deflection-roads
    set patches-roads patches with [patch-deflection-roads > 0]
  ]

  if(deflect-pipeline?)
  [
    gis:apply-raster patch-pipes_layer patch-deflection-pipeline
    set patches-pipeline patches with [patch-deflection-pipeline > 0]
  ]

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-caribou-harvest-dataset))
  gis:apply-raster patch-caribou-harvest-dataset patch-caribou-harvest

  set patch-whitefish-dataset gis:load-dataset "data/ascBounds/whitefish10Y.asc"
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-whitefish-dataset))
  gis:apply-raster patch-whitefish-dataset whitefish?

  ask patches with [whitefish? > 0] [set whitefish? true]
  set-vegetation-rank-lists
  ask patches
  [ set vegNonParRank 0
    set vegParRank 0 ]
  correct-vegetation
  set-streams ;sets connected patches based on patch streams value. Connects the gap present in the colville river. Connects Nuiqsut to the Colville.
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

;Spawn location checking for better testing.
to-report check-location [x y]
  let ocean-good true
  let wetness-good true
  let elevation-good true

  if x < -64.5 or x > 64.5
  [
    report false
  ]

  if y < -64.5 or y > 64.5
  [
    report false
  ]


  ifelse ([ocean] of patch x y) = 1
  [
    set ocean-good  false
  ]

  [
    set ocean-good true
  ]

  ifelse ([wetness] of patch x y) > 0.95
  [
    set wetness-good false
  ]
  [
    set wetness-good true
  ]

  ifelse ([elevation] of patch x y) > elevation-limit
  [
    set elevation-good  false
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

to test-flow
  ;Assign patch sets river ids (build river patch sets)
  ask patches [ set river-set [] ]
  let river-cords [-30 -28 1 -64 -7 -63 -14 -64 -22 -32 -50 -55 12 -64 22 -64]
  ;let river-cords [-30 -28 1 -64 -7 -63 -14 -52 -20 -30 -50 -55 12 -64 22 -64]
  let x 0

  while [x < length river-cords]
  [
    ask patch (item x river-cords) (item (x + 1) river-cords)
    [
      set river-id ((x / 2) + 1)
      sprout 1
      [
        let flow-id [river-id] of patch-here

        repeat 1000
        [
          ask patch-here [set river-set lput [flow-id] of myself river-set ];set pcolor red]
          let target neighbors with [connected? = true and not member? ([flow-id] of myself) river-set ]
          set target min-one-of target [elevation]
          carefully [ move-to target ]
          [
            move-to max-one-of (patches with [member? [flow-id] of myself river-set]) [pycor]
            set target neighbors with [connected? = true and not member? ([flow-id] of myself) river-set ]
            set target min-one-of target [elevation]
            ifelse target = NOBODY
            [ die ]
            [ move-to target ]
          ]
        ]
      ]
    ]

    set x x + 2
  ]

end

to visualize-rivers
  let x 0
  while [ x < 8 ]
  [
    let rand-col (2 + random 6)  + ((x + 1) * 10)
    ask patches with [ member? (x + 1) river-set ]
    [ set pcolor rand-col ] ;(2 + random 6)  + ((x + 1) * 10) ]
    set x x + 1
  ]
end

;;use this function to build a probability list from a weighted listed. Order doesn't matter
;;in the weighted list.
to-report build-prob-list [ weighted-list ]
  let sumWeight sum weighted-list
  let fracWeight map [ i -> i / sumWeight ] weighted-list

  let prob-list [ ]
  let x 1
  let prob-num item 0 fracWeight
  set prob-list lput prob-num prob-list

  while [x < length fracWeight]
  [
    set prob-num item (x - 1) prob-list + item x fracWeight

    set prob-list lput prob-num prob-list
    set x x + 1
  ]

  set prob-list replace-item (length prob-list - 1) prob-list 1
  ;set prob-list fput 0 prob-list

  ;show prob-list

  report prob-list
end

;;prob-list is your incoming probabilities associated with each centroid, selection-list is your list
;;of centroids or centroid ID's you can in turn use to reference your centroids.
to-report select-weighted-val [ prob-list selection-list ]
  let test? false
  let random-prob (1 + random 1000) / 1000
  let diff-list map [ i -> abs(i - random-prob)] prob-list
  let pos position (min diff-list) diff-list

  if test? [
    show random-prob
    show prob-list
    show diff-list
    show pos
  ]

  ifelse random-prob > item pos prob-list
  [
    if test? [ show (pos + 1) show item (pos + 1) prob-list ]
    report item (pos + 1) selection-list
  ]
  [
    if test? [ show pos show item pos prob-list ]
    report item pos selection-list
  ]
end

to-report select-weighted-val-new [ prob-list ]
  let test? false
  let random-prob (1 + random 1000) / 1000
  let diff-list map [ i -> abs(i - random-prob) ] prob-list
  let pos position (min diff-list) diff-list
  let result []

  if test? [
    show random-prob
    show prob-list
    show diff-list
    show pos
  ]

  ifelse random-prob > item pos prob-list
  [
    if test? [ show (pos + 1) show item (pos + 1) prob-list ]
    report (pos + 1)
  ]
  [
    if test? [ show pos show item pos prob-list ]
    report pos
  ]
end

to build-caribou-harvest-lists
  set caribou-harvest-selection-list [ ]
  set caribou-harvest-fRanks-list [ ]
  ask caribou-harvests
  [
    set caribou-harvest-selection-list lput who caribou-harvest-selection-list
    set caribou-harvest-fRanks-list lput (20 - frequency-rank) caribou-harvest-fRanks-list
  ]
end

to build-caribou-harvest-prob-list
  set caribou-harvest-probability-list build-prob-list caribou-harvest-fRanks-list
end

to export-hunter-data [mode]
  ;per trip, mode = 0
  if(mode = 0)
  [

    file-open "hunter-trip-data.txt"
    ask hunters
    [
      file-print ""
      file-write spent-time
      file-write ([who] of self)
      file-write prey-caught
      file-write harvest-patch
    ]
    file-close
  ]
  ;per year, mode = 1
  if(mode = 1)
  [
    let filename "hunter-year-data.txt"
    file-open filename
    ask hunters
    [
      file-print ""
      file-write year
      file-write ([who] of self)
      file-write harvest-amount
      file-write matrix:to-row-list hunter-fcm-matrix
    ]
    file-close
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
293
10
805
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
1
1
1
ticks
30.0

BUTTON
73
16
147
49
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
5
88
145
121
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
4
122
142
155
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
4
157
143
190
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
4
192
142
225
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
4
226
143
259
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
4
261
144
294
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
153
88
282
121
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
152
157
281
190
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
153
228
279
261
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
153
122
277
155
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
153
193
278
226
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
153
264
281
297
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
285
574
659
619
BoundsFile
BoundsFile
"data/ascBounds/CharDolly10Y.asc" "data/ascBounds/CharDolly12M.asc" "data/ascBounds/Cisco10Y.asc" "data/ascBounds/Cisco12M.asc" "data/ascBounds/MooseBounds10Y.asc" "data/ascBounds/MooseBounds12M.asc" "data/ascBounds/whitefish12m.asc" "data/ascBounds/whitefish10Y.asc" "data/development-regions/sm_Bear_Tooth.asc" "data/development-regions/sm_Beechey_Point.asc" "data/development-regions/sm_Colville_River.asc" "data/development-regions/sm_Dewline.asc" "data/development-regions/sm_Duck_Island.asc" "data/development-regions/sm_Greater_Mooses_Tooth.asc" "data/development-regions/sm_Kuparuk_River.asc" "data/development-regions/sm_Liberty.asc" "data/development-regions/sm_Milne_Point.asc" "data/development-regions/sm_Nikaitchuq.asc" "data/development-regions/sm_Northstar.asc" "data/development-regions/sm_Oooguruk.asc" "data/development-regions/sm_Pikka.asc" "data/development-regions/sm_Placer.asc" "data/development-regions/sm_Prudhoe_Bay.asc" "data/development-regions/sm_S_Miluveach.asc" "data/development-regions/pipes_layer.asc" "data/development-regions/roads_layer.asc"
24

BUTTON
286
627
414
660
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
418
627
496
660
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
584
642
756
675
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
584
677
758
710
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
150
17
213
50
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
193
869
356
902
elevation-limit
elevation-limit
0
1000
221.0
1
1
NIL
HORIZONTAL

SLIDER
191
718
353
751
caribou-amt
caribou-amt
0
50000
2500.0
500
1
NIL
HORIZONTAL

SLIDER
703
922
875
955
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
192
755
353
788
caribou-group-amt
caribou-group-amt
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
193
796
353
829
caribou-radius
caribou-radius
0
12
1.5
0.5
1
NIL
HORIZONTAL

BUTTON
4
296
144
329
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
358
665
556
698
set-centroid-attraction
set-centroid-attraction
0.01
1
0.1
0.01
1
NIL
HORIZONTAL

INPUTBOX
586
744
656
804
caribou-veg-factor
0.14
1
0
Number

INPUTBOX
660
744
730
804
caribou-rough-factor
0.215
1
0
Number

TEXTBOX
701
723
872
753
Caribou Utility Factors
12
13.0
1

INPUTBOX
735
743
805
803
caribou-insect-factor
0.294
1
0
Number

INPUTBOX
809
743
879
803
caribou-modifier-factor
0.215
1
0
Number

SLIDER
769
810
1003
843
caribou-modify-amt
caribou-modify-amt
0
1
1.0
0.01
1
NIL
HORIZONTAL

BUTTON
8
770
173
804
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
8
736
172
770
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
8
702
132
736
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

INPUTBOX
656
845
727
905
decay-rate
0.43
1
0
Number

SWITCH
4
356
206
389
show-caribou-utility?
show-caribou-utility?
1
1
-1000

INPUTBOX
758
846
881
906
caribou-max-wetness
0.8
1
0
Number

INPUTBOX
883
846
1005
906
caribou-max-elevation
700.0
1
0
Number

INPUTBOX
5
637
77
697
diffuse-amt
0.0
1
0
Number

INPUTBOX
83
638
149
698
elevation-scale
0.0
1
0
Number

INPUTBOX
882
743
953
803
caribou-deflection-factor
0.336
1
0
Number

INPUTBOX
968
1064
1032
1124
moose-max-elevation
700.0
1
0
Number

INPUTBOX
901
1063
965
1123
moose-max-wetness
0.8
1
0
Number

INPUTBOX
604
983
674
1043
moose-util-type-2
0.25
1
0
Number

INPUTBOX
677
983
749
1043
moose-util-type-3
0.66
1
0
Number

INPUTBOX
751
983
823
1043
moose-util-type-4
0.5
1
0
Number

INPUTBOX
826
983
900
1043
moose-util-type-5
0.66
1
0
Number

INPUTBOX
903
983
973
1043
moose-util-type-9
0.25
1
0
Number

INPUTBOX
601
1063
672
1123
moose-veg-factor
1.0
1
0
Number

INPUTBOX
674
1063
746
1123
moose-rough-factor
-5.0
1
0
Number

INPUTBOX
748
1063
821
1123
moose-insect-factor
0.5
1
0
Number

INPUTBOX
824
1063
895
1123
moose-deflection-factor
1.0
1
0
Number

MONITOR
817
60
874
105
Day
day
1
1
11

SWITCH
4
461
207
494
show-moose-utility?
show-moose-utility?
1
1
-1000

TEXTBOX
716
959
905
989
Moose Vegetation Values
12
0.0
1

TEXTBOX
691
1045
841
1063
Moose Utility Factors
12
0.0
1

TEXTBOX
38
335
188
353
Show Utility Values
12
0.0
1

TEXTBOX
206
663
356
681
Caribou Spawn Values
12
0.0
1

TEXTBOX
368
552
518
570
Show Harvest Bounds
12
0.0
1

TEXTBOX
906
1048
967
1066
Wetness
12
0.0
1

TEXTBOX
973
1048
1043
1066
Elevation
12
0.0
1

TEXTBOX
31
616
181
634
?? Insect Vals ??
12
0.0
1

TEXTBOX
599
625
749
643
Harvest Graph Nodes\n
12
0.0
1

MONITOR
816
10
873
55
Hour
hour
17
1
11

INPUTBOX
8
807
172
867
centroid-attraction-max
0.55
1
0
Number

INPUTBOX
9
872
170
932
centroid-attraction-min
0.04
1
0
Number

INPUTBOX
9
937
170
997
caribou-cent-dist-cutoff
20.0
1
0
Number

INPUTBOX
10
998
169
1058
caribou-util-cutoff
0.2
1
0
Number

SWITCH
449
1030
584
1063
is-training?
is-training?
0
1
-1000

MONITOR
817
109
874
158
Year
year
0
1
12

SWITCH
191
684
350
717
caribouPopMod?
caribouPopMod?
1
1
-1000

INPUTBOX
958
743
1020
803
caribou-precip-factor
0.561
1
0
Number

SLIDER
193
834
354
867
caribou-para
caribou-para
0
1
0.71
.01
1
NIL
HORIZONTAL

SWITCH
4
391
207
424
show-caribou-utility-para?
show-caribou-utility-para?
1
1
-1000

SWITCH
4
425
207
458
show-caribou-utility-non-para?
show-caribou-utility-non-para?
1
1
-1000

SLIDER
587
808
759
841
ndvi-weight
ndvi-weight
0
1
0.464
0.01
1
NIL
HORIZONTAL

INPUTBOX
586
846
655
906
energy-gain-factor
29.4
1
0
Number

SWITCH
312
1030
447
1063
is-random?
is-random?
1
1
-1000

SWITCH
188
1029
308
1062
debug-fcm?
debug-fcm?
1
1
-1000

TEXTBOX
1280
571
1348
594
HUNTERS
11
0.0
1

SLIDER
1052
670
1275
703
hunter-population
hunter-population
0
35
35.0
1
1
hunters
HORIZONTAL

SLIDER
1052
707
1275
740
hunter-vision
hunter-vision
0
20
2.0
1
1
* 2.2 km
HORIZONTAL

SLIDER
1316
632
1518
665
prey-close-constant
prey-close-constant
0
0.5
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
1298
673
1522
706
prey-far-constant
prey-far-constant
0.5
1
0.6
0.05
1
NIL
HORIZONTAL

SLIDER
1298
715
1521
748
trip-long-constant
trip-long-constant
0
0.50
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
1298
755
1522
788
trip-short-constant
trip-short-constant
0.50
1
0.6
0.05
1
NIL
HORIZONTAL

SWITCH
3
495
175
528
display-centroids?
display-centroids?
1
1
-1000

SWITCH
3
527
149
560
display-grids?
display-grids?
1
1
-1000

MONITOR
1499
12
1601
57
mean sim time
mean avg-sim-time
17
1
11

PLOT
878
10
1078
160
Number Unique Caribou FCMs
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if display-plots? [ plotxy (year) (length caribou-fcm-adja-list) ]"

PLOT
1078
10
1278
160
Mean Bioenergy of Caribou
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if display-plots? [plotxy ticks mean [bioenergy-success] of caribou]"

PLOT
818
164
1203
359
Caribou State Flux
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Evade" 1.0 0 -16777216 true "" "if display-plots? [ plotxy ticks count caribou with [state = 0] ]"
"Interforage" 1.0 0 -1264960 true "" "if display-plots? [ plotxy ticks count caribou with [state = 1] ]"
"Taxi/migrate" 1.0 0 -13791810 true "" "if display-plots? [ plotxy ticks count caribou with [state = 2] ]"
"Rest" 1.0 0 -1184463 true "" "if display-plots? [  plotxy ticks count caribou with [state = 3] ]"
"Intraforage" 1.0 0 -6459832 true "" "if display-plots? [ plotxy ticks count caribou with [state = 4] ]"

INPUTBOX
203
956
260
1016
Q-Gamma
0.999
1
0
Number

INPUTBOX
267
957
326
1017
Q-rate
0.001
1
0
Number

SWITCH
203
919
319
952
use-q
use-q
1
1
-1000

SWITCH
358
701
528
734
export-centroids?
export-centroids?
1
1
-1000

CHOOSER
358
875
496
920
mutation-method
mutation-method
"fuzzy-logic" "trivalent" "pentavalent"
0

SWITCH
358
737
517
770
caribou-mutate?
caribou-mutate?
0
1
-1000

SWITCH
358
773
540
806
caribou-recombine?
caribou-recombine?
0
1
-1000

SWITCH
348
956
534
989
calibrateCaribouVar?
calibrateCaribouVar?
1
1
-1000

SWITCH
336
991
546
1024
randomCaribouVarStart?
randomCaribouVarStart?
1
1
-1000

SLIDER
1053
743
1275
776
trip-length-max
trip-length-max
0
224
112.0
1
1
* 1.5 hrs
HORIZONTAL

SLIDER
1298
793
1507
826
boat-hike-long-constant
boat-hike-long-constant
0
1
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
1298
834
1513
867
boat-hike-short-constant
boat-hike-short-constant
0
1
0.6
.05
1
NIL
HORIZONTAL

SLIDER
1052
887
1294
920
caribou-harvest-low-constant
caribou-harvest-low-constant
0
1
0.4
.05
1
NIL
HORIZONTAL

SLIDER
1052
926
1301
959
caribou-harvest-high-constant
caribou-harvest-high-constant
0
1
0.6
0.05
1
NIL
HORIZONTAL

SLIDER
1052
780
1277
813
hunter-centroid-selection
hunter-centroid-selection
0
21
15.0
1
1
f-rank
HORIZONTAL

BUTTON
39
50
145
83
New Hunters
ask caribou-harvests [ht]\nask hunters [die]\nnew-hunters\n
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
149
51
251
84
Go Hunters
go-hunters-nls
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
769
638
1008
713
new-file
WetnessSumsAfter.txt
1
0
String

BUTTON
1051
1009
1144
1042
Open File
file-open new-file
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
1150
971
1244
1004
Close File
file-close\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
819
362
1493
569
Hunter State Flux
NIL
NIL
0.0
0.0
0.0
11.0
true
true
"" ""
PENS
"Hunt" 1.0 0 -16777216 true "" "if display-plots? [ plot count hunters with [prev-motor-state = 0] ]"
"Foot Travel " 1.0 0 -2139308 true "" "if display-plots? [ plot count hunters with [prev-motor-state = 1] ]"
"Boat Travel " 1.0 0 -11085214 true "" "if display-plots? [ plot count hunters with [prev-motor-state = 2] ]"
"Return " 1.0 0 -6917194 true "" "if display-plots? [ plot count hunters with [prev-motor-state = 3] ]"

BUTTON
1045
971
1146
1004
Write to File
file-open new-file \nask hunters [file-write wetness-sum / (patch-sum * 1.006791152)]\nfile-close
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
1050
632
1312
665
maximum-hunter-density
maximum-hunter-density
0
10
2.0
1
1
hunters/caribou group
HORIZONTAL

SLIDER
1308
872
1524
905
hunter-density-low-constant
hunter-density-low-constant
0
0.5
0.4
.05
1
NIL
HORIZONTAL

SLIDER
1309
909
1526
942
hunter-density-high-constant
hunter-density-high-constant
.5
1
0.6
0.05
1
NIL
HORIZONTAL

SLIDER
1053
816
1280
849
hunter-harvest-goal
hunter-harvest-goal
1
10
1.0
1
1
caribou
HORIZONTAL

MONITOR
1428
166
1537
211
Hunter Success
sum ([harvest-amount] of hunters)
2
1
11

SLIDER
1052
852
1280
885
local-search-radius
local-search-radius
0
10
3.0
1
1
patches
HORIZONTAL

SWITCH
1050
595
1190
628
use-hunters?
use-hunters?
0
1
-1000

SWITCH
349
921
530
954
exportCaribouData?
exportCaribouData?
0
1
-1000

BUTTON
1151
1009
1231
1042
line test
  let patch-list-t []\n  let num-t 0\n  let x1-t 3\n  let y1-t 1\n  let x2-t -4\n  let y2-t -30\n  let d-x (x2-t - x1-t)\n  let d-y (y2-t - y1-t)\n  let slope-t d-y / d-x\n  ifelse (abs d-x >  abs d-y)\n  [\n     let x-t x1-t\n     let y-t 0\n     ifelse (x2-t > x1-t)\n     [\n        while[x-t <= x2-t]\n        [\n          set y-t (slope-t * (x-t - x1-t) + y1-t)\n          set patch-list-t lput (patch x-t y-t) patch-list-t\n          set x-t (x-t + 1)\n        ]\n     ]\n     [\n        while[x-t >= x2-t]\n        [\n          set y-t (slope-t * (x-t - x1-t) + y1-t)\n          set patch-list-t lput (patch x-t y-t) patch-list-t\n          set x-t (x-t - 1)\n        ]\n     ]\n   ]  \n   [\n     let y-t y1-t\n     let x-t 0\n     ifelse (y2-t > y1-t)\n     [\n        while[y-t <= y2-t]\n        [;\n          set x-t ((y-t - y1-t) / slope-t + x1-t)\n          set patch-list-t lput (patch x-t y-t) patch-list-t\n          set y-t (y-t + 1)\n        ]\n     ]\n     [\n        while[y-t >= y2-t]\n        [;\n          set x-t ((y-t - y1-t) / slope-t + x1-t)\n          set patch-list-t lput (patch x-t y-t) patch-list-t\n          set y-t (y-t - 1)\n        ]\n     ]\n   ]\n  foreach patch-list-t\n  [ i ->\n      ask i \n      [\n         set pcolor red\n         if(streams > (0.025 * (max [streams] of patches)) or empty? river-set = false and pxcor != 3 and pycor != 1)\n         [set pcolor white]\n      ]\n  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1442
965
1603
998
hunter-recombine?
hunter-recombine?
0
1
-1000

SWITCH
1442
1002
1596
1035
hunter-mutate?
hunter-mutate?
0
1
-1000

SLIDER
357
808
544
841
caribou-mutate-prob
caribou-mutate-prob
0
1
0.15
.01
1
NIL
HORIZONTAL

SLIDER
357
842
549
875
caribou-recomb-prob
caribou-recomb-prob
0
1
0.2
.01
1
NIL
HORIZONTAL

SLIDER
1251
970
1437
1003
hunter-recomb-prob
hunter-recomb-prob
0
1
0.2
.1
1
NIL
HORIZONTAL

SLIDER
1251
1004
1437
1037
hunter-mutate-prob
hunter-mutate-prob
0
1
0.15
.1
1
NIL
HORIZONTAL

SWITCH
144
297
293
330
dynamic-display?
dynamic-display?
1
1
-1000

SWITCH
1194
593
1365
626
export-hunter-data?
export-hunter-data?
0
1
-1000

SWITCH
1368
592
1527
625
hunter-training?
hunter-training?
0
1
-1000

PLOT
1282
10
1496
160
Number Unique Hunter FCMs
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if display-plots? [ carefully [plotxy (year) (length hunter-fcm-adja-list)] [] ]"

SWITCH
1251
1039
1420
1072
random-hunter-fcm?
random-hunter-fcm?
0
1
-1000

SLIDER
188
1064
368
1097
prob-var-recombination
prob-var-recombination
0
1
0.33
.01
1
NIL
HORIZONTAL

PLOT
1214
166
1426
334
Total Success of Hunters
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if display-plots? [ plot sum ([harvest-amount] of hunters) ]"

SWITCH
1457
240
1601
273
display-plots?
display-plots?
1
1
-1000

SWITCH
151
529
283
562
collect-kde?
collect-kde?
0
1
-1000

SWITCH
370
1064
555
1097
import-caribou-var?
import-caribou-var?
0
1
-1000

SWITCH
182
1099
370
1132
import-caribou-fcm?
import-caribou-fcm?
0
1
-1000

SWITCH
4
563
115
596
Nuiqsut?
Nuiqsut?
0
1
-1000

SWITCH
119
564
222
597
CD5?
CD5?
0
1
-1000

SWITCH
1583
549
1729
582
deflect-pipeline?
deflect-pipeline?
1
1
-1000

SWITCH
1583
584
1729
617
deflect-roads?
deflect-roads?
1
1
-1000

SWITCH
1583
618
1730
651
deflect-oil?
deflect-oil?
1
1
-1000

CHOOSER
1511
408
1751
453
scenario
scenario
"none" "hunter-evolution-lo" "caribou-evolution-lo" "control-w-hunters-lo" "control-no-hunters-lo" "obd-w-hunters-lo" "obd-no-hunters-lo" "veg-later-shift-w-hunters-lo" "veg-later-shift-no-hunters-lo" "veg-early-shift-w-hunters-lo" "veg-early-shift-no-hunters-lo" "combined-early-ndvi-no-hunters-lo" "combined-early-ndvi-w-hunters-lo" "combined-late-ndvi-no-hunters-lo" "combined-late-ndvi-w-hunters-lo" "hunter-evolution-hi" "caribou-evolution-hi" "control-w-hunters-hi" "control-no-hunters-hi" "obd-w-hunters-hi" "obd-no-hunters-hi" "veg-later-shift-w-hunters-hi" "veg-later-shift-no-hunters-hi" "veg-early-shift-w-hunters-hi" "veg-early-shift-no-hunters-hi" "combined-early-ndvi-no-hunters-hi" "combined-early-ndvi-w-hunters-hi" "combined-late-ndvi-no-hunters-hi" "combined-late-ndvi-w-hunters-hi"
1

SWITCH
371
1099
529
1132
use-high-res-ndvi?
use-high-res-ndvi?
1
1
-1000

BUTTON
373
1136
466
1169
Show NDVI
show-ndvi
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
692
562
811
595
Rapid Year Test
set day 255
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1584
356
1751
389
export-logger-data?
export-logger-data?
1
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
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="nsb-abm-ndvi-cal" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="show-caribou-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-veg-factor">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-scale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-deflection-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-radius">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-cent-dist-cutoff">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-centroid-attraction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-insect-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-training?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-precip-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="ndvi-weight" first="0.1" step="0.1" last="1"/>
    <enumeratedValueSet variable="mutation-method">
      <value value="&quot;fuzzy-logic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-q">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-para">
      <value value="0.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-grids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BoundsFile">
      <value value="&quot;data/ascBounds/CharDolly10Y.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-hunter-energy">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-2">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-veg-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recomb-prob">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-limit">
      <value value="231"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recombination?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-random?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modifier-factor">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-non-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-close-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-min">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-5">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-far-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-deflection-factor">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-3">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-moose-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribouPopMod?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-insect-factor">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-vision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-Gamma">
      <value value="0.999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-rough-factor">
      <value value="2.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuse-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-para?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modify-amt">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-9">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-util-cutoff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-group-amt">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-rough-factor">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-max">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-gain-factor">
      <value value="33.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-amt">
      <value value="2500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="All Deflect" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>Year = 100</exitCondition>
    <enumeratedValueSet variable="new-file">
      <value value="&quot;WetnessSumsAfter.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibrateCaribouVar?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recomb-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BoundsFile">
      <value value="&quot;data/development-regions/pipes_layer.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-var-recombination">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-min">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-grids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-training?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuse-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-amt">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-deflection-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate">
      <value value="0.781"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-group-amt">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-9">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-cent-dist-cutoff">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-non-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportCaribouData?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-pipeline?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-roads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-hunter-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-insect-factor">
      <value value="0.436"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-gain-factor">
      <value value="42.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-grad-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-search-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-hunters?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomCaribouVarStart?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-Gamma">
      <value value="0.999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recombine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-close-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-rough-factor">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-moose-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ndvi-weight">
      <value value="0.631"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-centroid-selection">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-scale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nuiqsut?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-far-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-veg-factor">
      <value value="0.109"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-3">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-5">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modify-amt">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-max">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-para">
      <value value="0.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-rough-factor">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CD5?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-oil?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modifier-factor">
      <value value="0.321"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-hunter-data?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-precip-factor">
      <value value="0.158"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-training?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-deflection-factor">
      <value value="0.506"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-kde?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-random?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recombine?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-var?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recomb-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-hunter-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-radius">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-centroid-attraction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-q">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-mut-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-display?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-fcm?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribouPopMod?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-veg-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-limit">
      <value value="221"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-2">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-util-cutoff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-plots?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-population">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-length-max">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-harvest-goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-method">
      <value value="&quot;fuzzy-logic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-insect-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Oil" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>Year = 100</exitCondition>
    <enumeratedValueSet variable="new-file">
      <value value="&quot;WetnessSumsAfter.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibrateCaribouVar?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recomb-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BoundsFile">
      <value value="&quot;data/development-regions/pipes_layer.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-var-recombination">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-min">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-grids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-training?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuse-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-amt">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-deflection-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate">
      <value value="0.781"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-group-amt">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-9">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-cent-dist-cutoff">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-non-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportCaribouData?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-pipeline?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-roads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-hunter-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-insect-factor">
      <value value="0.436"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-gain-factor">
      <value value="42.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-grad-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-search-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-hunters?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomCaribouVarStart?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-Gamma">
      <value value="0.999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recombine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-close-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-rough-factor">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-moose-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ndvi-weight">
      <value value="0.631"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-centroid-selection">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-scale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nuiqsut?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-far-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-veg-factor">
      <value value="0.109"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-3">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-5">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modify-amt">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-max">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-para">
      <value value="0.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-rough-factor">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CD5?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-oil?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modifier-factor">
      <value value="0.321"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-hunter-data?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-precip-factor">
      <value value="0.158"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-training?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-deflection-factor">
      <value value="0.506"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-kde?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-random?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recombine?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-var?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recomb-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-hunter-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-radius">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-centroid-attraction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-q">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-mut-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-display?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-fcm?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribouPopMod?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-veg-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-limit">
      <value value="221"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-2">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-util-cutoff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-plots?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-population">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-length-max">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-harvest-goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-method">
      <value value="&quot;fuzzy-logic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-insect-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Only Oil" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>Year = 100</exitCondition>
    <enumeratedValueSet variable="new-file">
      <value value="&quot;WetnessSumsAfter.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibrateCaribouVar?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recomb-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BoundsFile">
      <value value="&quot;data/development-regions/pipes_layer.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-var-recombination">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-min">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-grids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-training?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuse-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-amt">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-deflection-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate">
      <value value="0.781"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-group-amt">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-9">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-cent-dist-cutoff">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-non-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportCaribouData?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-pipeline?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-roads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-hunter-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-insect-factor">
      <value value="0.436"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-gain-factor">
      <value value="42.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-grad-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-search-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-hunters?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomCaribouVarStart?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-Gamma">
      <value value="0.999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recombine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-close-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-rough-factor">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-moose-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ndvi-weight">
      <value value="0.631"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-centroid-selection">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-scale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nuiqsut?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-far-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-veg-factor">
      <value value="0.109"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-3">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-5">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modify-amt">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-max">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-para">
      <value value="0.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-rough-factor">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CD5?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-oil?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modifier-factor">
      <value value="0.321"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-hunter-data?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-precip-factor">
      <value value="0.158"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-training?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-deflection-factor">
      <value value="0.506"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-kde?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-random?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recombine?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-var?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recomb-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-hunter-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-radius">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-centroid-attraction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-q">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-mut-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-display?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-fcm?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribouPopMod?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-veg-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-limit">
      <value value="221"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-2">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-util-cutoff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-plots?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-population">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-length-max">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-harvest-goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-method">
      <value value="&quot;fuzzy-logic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-insect-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>year = 1</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="hunter-density-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CD5?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-gain-factor">
      <value value="42.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate">
      <value value="0.781"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-random?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-hunters?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-precip-factor">
      <value value="0.158"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-plots?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recombine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-util-cutoff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-Gamma">
      <value value="0.999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-para">
      <value value="0.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribouPopMod?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-population">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuse-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-training?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-9">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-veg-factor">
      <value value="0.109"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibrateCaribouVar?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-var?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nuiqsut?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-insect-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-grad-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-method">
      <value value="&quot;fuzzy-logic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-non-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-centroid-attraction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-mut-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-roads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-hunter-data?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-q">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-veg-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-deflection-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-pipeline?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-hunter-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-hunter-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-deflection-factor">
      <value value="0.506"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-rough-factor">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-amt">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modifier-factor">
      <value value="0.321"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-radius">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-oil?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-grids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-2">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-kde?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-fcm?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ndvi-weight">
      <value value="0.631"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-far-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recombine?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-close-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modify-amt">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-length-max">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-group-amt">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-centroid-selection">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-scale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-5">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-harvest-goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomCaribouVarStart?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BoundsFile">
      <value value="&quot;data/development-regions/pipes_layer.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-3">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-moose-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-var-recombination">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recomb-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recomb-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-cent-dist-cutoff">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportCaribouData?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-rough-factor">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-insect-factor">
      <value value="0.436"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-training?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-display?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-limit">
      <value value="221"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-min">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-max">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-file">
      <value value="&quot;WetnessSumsAfter.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-search-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="file-output-prepend" first="1" step="1" last="100"/>
  </experiment>
  <experiment name="caribou_variable_evolution" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>year = 1000</exitCondition>
    <enumeratedValueSet variable="energy-gain-factor">
      <value value="34.699999999999996"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recombine?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-low-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-var?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-random?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-plots?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-length-max">
      <value value="112"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-scale">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportCaribouData?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-group-amt">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-q">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-method">
      <value value="&quot;fuzzy-logic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BoundsFile">
      <value value="&quot;data/development-regions/pipes_layer.asc&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-rough-factor">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-training?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-deflection-factor">
      <value value="0.4170000000000001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-mut-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-insect-factor">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-max">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-radius">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-hunter-data?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-hunter-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-wetness">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-vision">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boat-hike-short-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-max-elevation">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribouPopMod?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="export-centroids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-4">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-insect-factor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calibrateCaribouVar?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-amt">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuse-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-para">
      <value value="0.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="set-centroid-attraction">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-roads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-grids?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Nuiqsut?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ndvi-weight">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-hunters?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-harvest-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-5">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-precip-factor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CD5?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate-prob">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-9">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-Gamma">
      <value value="0.999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-harvest-goal">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="var-grad-prob-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-util-cutoff">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-cent-dist-cutoff">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay-rate">
      <value value="0.754"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomCaribouVarStart?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-veg-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recomb-prob">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-pipeline?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new-file">
      <value value="&quot;WetnessSumsAfter.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="centroid-attraction-min">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-hunter-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="is-training?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Q-rate">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modify-amt">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-search-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-density-high-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-display?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="import-caribou-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-3">
      <value value="0.66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trip-long-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-close-constant">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevation-limit">
      <value value="221"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-util-type-2">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-moose-utility?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-recomb-prob">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-var-recombination">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-modifier-factor">
      <value value="0.473"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prey-far-constant">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-centroid-selection">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-population">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug-fcm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-veg-factor">
      <value value="0.08200000000000002"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-rough-factor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunter-mutate?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-amt">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-caribou-utility-non-para?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collect-kde?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="caribou-recombine?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="moose-deflection-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-oil?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
