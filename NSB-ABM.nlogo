;Main code for the ABM

;Zip file w/ model and data:
;https://drive.google.com/a/alaska.edu/file/d/0B6Qg-B9DYEuKVE5EQldZMjUtRlE/view?usp=sharing


extensions [ gis array matrix table csv]

__includes["nls-modules/insect.nls" "nls-modules/precip.nls" "nls-modules/NDVI.nls" "nls-modules/caribouPop.nls"
           "nls-modules/caribou.nls" "nls-modules/moose.nls"; "nls-modules/hunters.nls"
  "nls-modules/fcm.nls" "nls-modules/patch-list.nls" "nls-modules/utility-functions.nls" "nls-modules/display.nls" "nls-modules/connectivityCorrection.nls" "nls-modules/vegetation-rank.nls"
  "nls-modules/migration-grids.nls" "nls-modules/migration-centroids.nls"]


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
  years-store
  fcm-store
  ticks-store
  bio-en-store

;GIS DATA
  np-centroid-network
  p-centroid-network
  cent-day-list ;for recording list of days where the centroids need to be reassigned in the simulation
  avg-sim-time ;for reporting the average amount of time it takes to simulate each year.

  fcm-adja-list
  fcm-agentnum-list
  fcm-success-list

  patch-roughness-dataset
  patch-wetness-dataset
  patch-streams-dataset
  patch-elevation-dataset
  patch-ocean-dataset
  patch-whitefish-dataset
  patch-caribou-harvest-dataset

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


  ;PatchList for movement decisions
  patch-coord-x
  patch-coord-y
  patch-list-exists
  patch-list-utility
  patch-array-iterator
  ;;WORK AROUND NUMBERS;; These numbers are used to work around limitations with the
  ;    NetLogo language

  caribou-bio-list
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

caribou-own
[
  cent-memory ;try length 20 - value from Semenuik?
  grid-memory
  bioenergy-success ;acknowledges that it's impossible for a caribou to acquire hundreds of thousands of MJ. Serves to limit inputs to FCM

  energy-gain ; Update Q Learning w/ energy
  energy-loss
  group-size
  radius
  energy
  weight
  fd-amt

  scaled-bio
  changed-states?

  ;Actions
  bank-rest
  bank-intra
  bank-inter
  bank-migrate

  ;;Movement Values in relation to Semeniuk et al
  ;;  differs by being 3x as long compared to Semeniuk. Currently 90 minutes instead of 30 minutes
  ;forage intra-patch
  fga-amt
  ;forage inter-patch
  fge-amt
  ;migrate/taxi
  mg-amt-min
  mg-amt-max
  last-winner-caribou-val
  ;goal patch for foraging
  goal-patch
  goal-reached

  caribou-class ; Caribou Class 0 - Male, 1 - Female,  2 - Female/Parturition

  ;FCM
  cog-map
  ;actVals
  util-low
  util-high
  taxi-state
  forage-state
  cent-dist-close
  cent-dist-far


  ;--New FCM--
  ;FCM Control
  close-range ;  ex: 1.2
  far-range ; ex: 1.8
  fcm-sigmoid-scalar ; currently always set to 1


  ;Q-Net
  net-x
  net-w1
  net-s1
  net-z1
  net-w2
  net-s2
  net-z2
  net-wout
  net-sout



  bioenergy-saved
  bioenergy-upper ;The upper limit for the FCM ternary calculation for energy
  bioenergy-lower ;The lower limit for the FCM Ternary calculation for energy
  ;--FCM Sensors--
  ;0; foe-close
  ;1; foe-far
  ;2; food-close ;neighbor cells?
  ;3; food-far
  ;4; energy-low
  ;5; energy-high
  ;6; food-quantity-low ;lichen content?
  ;7; food-quantity-high
  ;;;----Sensors not in  R. Gras et al.---
  ;8; disturb-close
  ;9; disturb-far

  fcm-mat-sensor ;sensor values placed into a matrix representing the previous values
  fcm-mat-conc-delta ; the stored values for concepts and motor states 1 x 11 (top 6 represent concepts, trailing 5 represent motor states)
  fcm-adja ; Adjacency list for all actions, sub-list taken for matrix operations

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
  current-grid
  last-grid


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

cent-links-own
[
  link-weight
]

;wraps to other setup functions
to setup
  clear-all
  random-seed 0
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

  centroid-read
  grid-read
  ;centroid-weight-io
  centroid-weight-master-io

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

  setup-hunters-temp
  setup-precipitation
  setup-terrain-layers
  setup-caribou-utility ;setup caribou utility code requires a fix, semantics of it don't make sense.
  ;update-caribou-utility
  ;update-para-utility
  ;update-non-para-utility
  setup-moose-utility
  setup-moose
  ;setup-centroids
  setup-caribou
  setup-caribou-q

  setup-patch-list
  setup-insect
  set-precipitation-data-list
  if(is-random?)
  [
   caribou-random-fcm
  ]

  set fcm-adja-list [fcm-adja] of caribou
 ; setup-ndvi
  go-veg-ranking
  set-streams

  ask patches
  [ set grid-util-non-para 0
    set grid-util-para 0 ]

  reset-ticks

  set ticks-store [ ]
  set bio-en-store [ ]

  set ticks-store lput ticks ticks-store
  set bio-en-store lput mean [bioenergy] of caribou bio-en-store

  set years-store [ ]
  set fcm-store [ ]

  set years-store lput year years-store
  set fcm-store lput (length fcm-adja-list) fcm-store

  test-flow
  let counter 1
  let xc -64 let yc 64 while [ yc >= -64]  [ ask patch xc yc [set patch-id counter] set counter counter + 1 set xc xc + 1 if xc >= 65 [ set yc yc - 1 set xc -64 ] ]
end

to setup-hunters-temp
create-hunters 1
[
  setxy 5 5
]


end
to setup-caribou-harvests
  ask patches
  [
    if (pxcor mod 1 = 0) and (pycor mod 1 = 0)
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
    set size 1.5
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
  ;create test deflector.
  create-deflectors 1
  [
    setxy 0 0
    set area-outer (3000 / 2195.35)
    set area-inner 0
    set deflect-amt 1
    set has-applied false
    set size 0
  ]


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

      export-fcm-data ;;at end of year, export FCMs, success thereof, and stateflux (just export individual state flux variables.)

      if(is-training? and day >= 258)
      [
        update-caribou-fcm
        ;export-fcm
      ]

      ifelse year = 0 [centroid-weight-master-io] [centroid-weight-io]

      if export-centroids? [ centroid-export ]

      set year year + 1

      set years-store lput year years-store
      set fcm-store lput (length fcm-adja-list) fcm-store

      set day 152
      if year = 100 [ stop ] ; can be deleted, just for network recording.
      set avg-sim-time lput timer avg-sim-time
      reset-timer
    ]



  if day = 152 [ go-insect ]
  if day = 166 [ go-insect ]
  if day = 181 [ go-insect ]
  if day = 196 [ go-insect ]
  if day = 212 [ go-insect ]
  if day = 227 [ go-insect ]


  ;build-mean-utility-lists

    if (day - 12) mod 14 = 0
    ;if abs (mean [caribou-utility-non-para] of patches - non-para-check) > 0.000000001 ;mean [caribou-utility-para] of patches != para-check or
    [
      ;centroid-test
      centroid-read
      grid-read

      ask caribou [ reset-caribou-centroids ]

    ]

    ifelse year = 0 [centroid-weight-master-io] [centroid-weight-io]

    ;centroid-export
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
  go-precipitation
  update-caribou-utility
  update-para-utility
  update-non-para-utility
  update-moose-utility
  go-dynamic-display
  update-caribou-state-data

  tick

  set ticks-store lput ticks ticks-store
  set bio-en-store lput mean [bioenergy] of caribou bio-en-store
end

to update-caribou-state-data
  let file-ex "caribou-state-flux-bioE.txt"
  file-open file-ex
  file-write ticks
  file-write count caribou with [state = 0]
  file-write count caribou with [state = 1]
  file-write count caribou with [state = 2]
  file-write count caribou with [state = 3]
  file-write count caribou with [state = 4]
  file-write mean [ bioenergy-success ] of caribou
  file-close
end

to export-fcm-data
  ;;dump all pertinent data every year for variable calibration.
  set fcm-adja-list [fcm-adja] of caribou
  let file-ex "caribou-fcms-agentnum-success.txt"
  file-open file-ex
  file-write year
  file-write (length fcm-adja-list)
  build-fcm-data
  file-write matrix:to-row-list fcm-adja-list
  file-write fcm-agentnum-list
  file-write fcm-success-list
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

  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of patch-wetness-dataset))

  gis:apply-raster patch-wetness-dataset wetness
  gis:apply-raster patch-roughness-dataset roughness
  gis:apply-raster patch-streams-dataset streams
  gis:apply-raster patch-elevation-dataset elevation
  gis:apply-raster patch-ocean-dataset ocean
  gis:apply-raster patch-vegetation-dataset vegetation-type

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

;

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
      ;set pcolor yellow
      sprout 1
      [
       ;let random-color 10 + random 10
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
         ;ask patch-here []
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
@#$#@#$#@
GRAPHICS-WINDOW
278
10
792
545
64
64
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
0

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
76
1155
109
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
121
1157
154
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
221
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
2500
500
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
0
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
50
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
1.5
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
0.1
0.01
1
NIL
HORIZONTAL

INPUTBOX
1271
378
1341
438
caribou-veg-factor
0.08
1
0
Number

INPUTBOX
1345
378
1415
438
caribou-rough-factor
2.3
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
0.7
1
0
Number

INPUTBOX
1494
377
1564
437
caribou-modifier-factor
0.1
1
0
Number

SLIDER
700
743
934
776
caribou-modify-amt
caribou-modify-amt
0
1
1
0.01
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
700
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
0
1
0
Number

INPUTBOX
552
660
618
720
elevation-scale
0
1
0
Number

INPUTBOX
1567
377
1638
437
caribou-deflection-factor
0.3
1
0
Number

INPUTBOX
267
661
331
721
moose-max-elevation
700
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
1
1
0
Number

INPUTBOX
1347
585
1419
645
moose-rough-factor
-5
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
1
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
804
550
1007
583
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
59
1148
77
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
20
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

SWITCH
1033
495
1168
528
is-training?
is-training?
0
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
804
585
963
618
caribouPopMod?
caribouPopMod?
1
1
-1000

INPUTBOX
1643
377
1705
437
caribou-precip-factor
1
1
0
Number

SLIDER
801
372
992
405
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
796
466
999
499
show-caribou-utility-para?
show-caribou-utility-para?
0
1
-1000

SWITCH
796
500
999
533
show-caribou-utility-non-para?
show-caribou-utility-non-para?
1
1
-1000

SLIDER
1274
309
1693
342
ndvi-weight
ndvi-weight
0
1
0.5
0.01
1
NIL
HORIZONTAL

INPUTBOX
978
719
1047
779
energy-gain-factor
33.7
1
0
Number

SWITCH
1034
460
1169
493
is-random?
is-random?
0
1
-1000

BUTTON
1064
374
1127
407
test
ask a-caribou 119 [\n\nprint \"Matrix sense state:\" \nprint (matrix:pretty-print-text fcm-mat-sensor)\n\nlet sens-adj matrix:transpose(matrix:submatrix fcm-adja 0 0 10 6)\n;\nlet internal matrix:times sens-adj fcm-mat-sensor\nset internal matrix:map fcm-sigmoid-simple internal\n    \n;weights for actions\nlet conc-adj matrix:transpose(matrix:submatrix fcm-adja 10 6 16 11) \nlet final-states matrix:times conc-adj internal\n\nprint \"Matrix final states:\" \nprint (matrix:pretty-print-text final-states)\n]\n
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
1038
427
1158
460
debug-fcm?
debug-fcm?
1
1
-1000

TEXTBOX
1271
652
1339
675
HUNTERS
11
0.0
1

SLIDER
1189
680
1412
713
hunter-population
hunter-population
0
100
1
1
1
NIL
HORIZONTAL

SLIDER
1189
720
1412
753
hunter-vision
hunter-vision
0
20
1
1
1
NIL
HORIZONTAL

SLIDER
1189
760
1412
793
initial-hunter-energy
initial-hunter-energy
0
2000
1000
50
1
NIL
HORIZONTAL

SLIDER
1423
680
1646
713
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
1423
720
1647
753
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
1423
761
1646
794
energy-low-constant
energy-low-constant
0
0.50
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
1424
801
1648
834
energy-high-constant
energy-high-constant
0.50
1
0.6
0.05
1
NIL
HORIZONTAL

SWITCH
982
653
1154
686
display-centroids?
display-centroids?
1
1
-1000

SWITCH
982
685
1128
718
display-grids?
display-grids?
1
1
-1000

MONITOR
975
10
1077
55
mean sim time
mean avg-sim-time
17
1
11

MONITOR
636
608
767
653
mean caribou state
mean [state] of caribou
17
1
11

PLOT
211
802
411
952
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
"default" 1.0 0 -16777216 true "" "plotxy (year) (length fcm-adja-list)"

PLOT
411
802
611
952
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
"default" 1.0 0 -16777216 true "" "plotxy ticks mean [bioenergy-success] of caribou"

PLOT
625
795
1010
990
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
"Evade" 1.0 0 -16777216 true "" "plotxy ticks count caribou with [state = 0]"
"Interforage" 1.0 0 -1264960 true "" "plotxy ticks count caribou with [state = 1]"
"Taxi/migrate" 1.0 0 -13791810 true "" "plotxy ticks count caribou with [state = 2]"
"Rest" 1.0 0 -1184463 true "" "plotxy ticks count caribou with [state = 3]"
"Intraforage" 1.0 0 -6459832 true "" "plotxy ticks count caribou with [state = 4]"

INPUTBOX
1044
900
1101
960
Q-Gamma
0.999
1
0
Number

INPUTBOX
1167
901
1226
961
Q-rate
0.001
1
0
Number

SWITCH
1044
863
1160
896
use-q
use-q
1
1
-1000

SWITCH
66
520
236
553
export-centroids?
export-centroids?
1
1
-1000

CHOOSER
1417
151
1555
196
mutation-method
mutation-method
"fuzzy-logic" "trivalent" "pentavalent"
0

INPUTBOX
1443
85
1531
145
mutate-prob
0.1
1
0
Number

SWITCH
1430
48
1548
81
mutation?
mutation?
1
1
-1000

SWITCH
1551
47
1703
80
recombination?
recombination?
1
1
-1000

INPUTBOX
1587
85
1676
145
recomb-prob
0.5
1
0
Number

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
NetLogo 5.3.1
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
