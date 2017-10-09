;Caribou pop dynamics code.
;This is the stand alone NetLogo code for it. A new .nls file version of it
;should be made and integrated with the mothership model.

;Please also download the population model from:
;https://drive.google.com/drive/folders/0B2Cp1O98r_vxSFMyNHdHRlZuMTg?usp=sharing

;The reason for this is to obtain the interface variables and commands if
;you intend on running this model standalone.
;The model at the above link is periodically updated based on the GitHub
;repository.

globals [ caribou-pop r ]
breed [ caribou a-caribou ]

to setup
  clear-all
  let num-agents round (start-pop / caribou/agent)
  ask n-of num-agents patches
  [
   sprout-caribou 1
  ]
  set caribou-pop count caribou * caribou/agent
  reset-ticks
end


to go
  let carrying-cap 65000 ;Appears to be carrying capacity based off of ADFG GMU 26A
                         ;data, Tab. 4, 2014.
  let chance (caribou-pop / carrying-cap)
  let roll (1 + random 100) / 100
  ifelse roll <= chance
  [
    set r -1 * random-exponential 6.84 ;Exponential parameter from fitted ADFG
                                       ;GMU 26A data, Tab. 4, 2014.
                                       ;Fit was made using data from 1984-2008.
  ]
  [
    set r random-exponential 6.84
  ]
  set r r / 100
  let new-pop caribou-pop * (exp r)
  let num-agents round (new-pop / caribou/agent)

    ifelse count caribou > num-agents
  [
    let diff count caribou - num-agents
    ask n-of diff caribou [ die ]
  ]
  [
    if count caribou < num-agents
    [
      let diff num-agents - count caribou
      ask n-of diff patches
      [
        sprout-caribou 1
      ]
    ]
  ]

  set caribou-pop count caribou * caribou/agent

  tick
end
