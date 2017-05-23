;Moose pop dynamics code.
;This is the stand alone NetLogo code for it. A new .nls file version of it
;should be made and integrated with the mothership model.

;Please also download the population model from:
;https://drive.google.com/drive/folders/0B2Cp1O98r_vxSFMyNHdHRlZuMTg?usp=sharing

;The reason for this is to obtain the interface variables and commands if
;you intend on running this model standalone.
;The model at the above link is periodically updated based on the GitHub
;repository.

globals [ moose-pop r ]
breed [ moose a-moose ]

to setup
  clear-all
  let num-agents round (start-pop / moose/agent)
  ask n-of num-agents patches
  [
   sprout-moose 1
  ]
  set moose-pop count moose * moose/agent
  reset-ticks
end


to go
  let carrying-cap 1500 ;Appears to be carrying capacity based off of ADFG GMU 26A
                         ;data, Tab. 4, 2014.
  let chance (moose-pop / carrying-cap)
  let roll (1 + random 100) / 100
  ifelse roll <= chance
  [
    set r -1 * random-exponential 15 ;exponential parameter from fitted ADFG
                                       ;GMU 26A data, Tab. 4, 2014.
  ]
  [
    set r random-exponential 15
  ]
  set r r / 100
  let new-pop moose-pop * (exp r)
  let num-agents round (new-pop / moose/agent)

    ifelse count moose > num-agents
  [
    let diff count moose - num-agents
    ask n-of diff moose [ die ]
  ]
  [
    if count moose < num-agents
    [
      let diff num-agents - count moose
      ask n-of diff patches
      [
        sprout-moose 1
      ]
    ]
  ]

  set moose-pop count moose * moose/agent

  tick
end
