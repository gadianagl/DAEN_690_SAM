globals [
  quarter
  colors
  color-names
  num-colors
  used-colors
  n/a
]

patches-own []

breed [ companies company ]
breed [ customers customer ]

customers-own [
  cust-id
  cust-rtrn
  cust-prin
  cust-comp-id
  cust-happy
  cust-type
  cust-toler
]

companies-own [
  comp-id
  comp-fee
  comp-gross
  comp-cost
  comp-net
  comp-prin
  comp-cust-cnt
  comp-mean-rtrn
  comp-test
  comp-rtrn-accu
  comp-fix-cost
  comp-vari-cost
]

to setup
  clear-patches
  clear-turtles
  clear-output
  setup-globals

  ;; comopany types
  setup-companies "Test-V" blue V-comp-num V-rtrn-accu V-fix-cost V-vari-cost V-fee
  setup-companies "Test-W" orange W-comp-num W-rtrn-accu W-fix-cost W-vari-cost W-fee
  setup-companies "Test-X" pink X-comp-num X-rtrn-accu X-fix-cost X-vari-cost X-fee
  setup-companies "Test-Y" violet Y-comp-num Y-rtrn-accu Y-fix-cost Y-vari-cost Y-fee
  setup-companies "Test-Z" gray Z-comp-num Z-rtrn-accu Z-fix-cost Z-vari-cost Z-fee

  ;; customer types
  setup-customers "AAA" yellow AAA-cust-num AAA-toler AAA-init-prin
  setup-customers "BBB" green BBB-cust-num BBB-toler BBB-init-prin
  setup-customers "CCC" red CCC-cust-num CCC-toler CCC-init-prin
  clear-all-plots
end

to setup-globals
  reset-ticks
  set quarter 0
  set-default-shape customers "face neutral"
  set colors      [ lime   orange   brown   yellow  turquoise  cyan   sky   blue
    violet   magenta   pink  red  green  gray  12 62 102 38 ]
  set color-names ["lime" "orange" "brown" "yellow" "turquoise" "cyan" "sky" "blue"
    "violet" "magenta" "pink" "red" "green" "gray" "maroon" "hunter green" "navy" "sand"]
  set used-colors []
  set num-colors length colors
  set n/a "n/a"
end

to setup-companies [ cptype cpcolor cpnum cpaccu cpfixcost cpvaricost cpfee]
  create-companies cpnum
  [
    set comp-test cptype
    set comp-id who
    set size 1.2
    set color cpcolor
    set comp-fee random-float cpfee
    set comp-mean-rtrn 0
    comp-set-loc
    set comp-rtrn-accu cpaccu
    set comp-fix-cost cpfixcost
    set comp-vari-cost cpvaricost
  ]
end

to setup-customers [ ctype ccolor cnum ctoler cinit]
  create-customers cnum
  [
    setxy random-xcor random-ycor
    set cust-id who
    set color ccolor
    set size 0.4
    set cust-comp-id -1
    set cust-prin (random-float (cinit / 2)) + (cinit / 2)
    set cust-happy 0
    set cust-type ctype
    set cust-toler ctoler
  ]
end

to go
  ask customers [
    cust-check-happy
    if ((cust-happy < cust-toler) OR (cust-comp-id = -1))
    [ cust-eval-comp ]
  ]
  ask customers [ cust-move ]
  ask companies [ comp-invest ]
  end-qtr

  tick
end

to cust-check-happy
  let mean-market mean [cust-rtrn] of customers

  ifelse (cust-rtrn < mean-market)
  [ set cust-happy 0
    set cust-happy cust-happy - 1 ]
  [ set cust-happy 0
    set cust-happy cust-happy + 1 ]
end

to cust-eval-comp
  let temp-id cust-comp-id
  let set-id -1
  let fee-val 0
  let dist-val 0
  let rtrn-val 0
  let comp-val 0
  let vs-val 0
  let weight-tot (fee-weight + dist-weight + rtrn-weight)

  let comp-rad companies in-radius (world-width / 3)	;; create subset of companies in given radius from the customer

  let fee-min min [ comp-fee ] of comp-rad
  let fee-max max [ comp-fee ] of comp-rad
  let dist-min distance min-one-of comp-rad [distance myself]
  let dist-max distance max-one-of comp-rad [distance myself]
  let rtrn-min min [ comp-mean-rtrn ] of comp-rad
  let rtrn-max max [ comp-mean-rtrn ] of comp-rad

  ask comp-rad with [comp-id != temp-id]
  [
    ifelse (fee-max = fee-min)	;; decreasing preference
    [ set fee-val 0]
    [ set fee-val (comp-fee - fee-max)/(fee-min - fee-max)]

    ifelse (dist-max = dist-min)	;; decreaseing preference
    [ set dist-val 0]
    [ set dist-val (distance myself - dist-max)/(dist-min - dist-max)]

    ifelse (rtrn-max = rtrn-min) ;; increasing preference
    [ set rtrn-val 0]
    [ set rtrn-val (comp-mean-rtrn - rtrn-min)/(rtrn-max - rtrn-min)]

    ;; weighted values/consider implementing slider variable for the weights
    set vs-val (fee-val * (fee-weight / weight-tot)) + (dist-val * (dist-weight / weight-tot)) + (rtrn-val * (rtrn-weight / weight-tot))

    if (vs-val > comp-val)
    [ set set-id comp-id ]
  ]

  set cust-comp-id set-id
end

to comp-invest
  let temp-id comp-id
  let my-cust customers with [ cust-comp-id = temp-id ]	;; create subset of customers with current company id
  let accu comp-rtrn-accu

  ask my-cust
  [
    let temp-rate vary-rate (-1 * rtrn-rate * (1 - accu)) rtrn-rate
    ifelse (cust-prin > 0)
    [ set cust-rtrn cust-prin * temp-rate ]
    [ set cust-rtrn 0 ]
    set cust-prin cust-prin + cust-rtrn
  ]
  set comp-prin sum [cust-prin] of my-cust
  set comp-gross comp-fee * comp-prin
  set comp-cust-cnt count my-cust
  set comp-cost ((comp-prin * comp-fix-cost) + (comp-cust-cnt * comp-vari-cost))
  set comp-net comp-gross - comp-cost

  ifelse (comp-cust-cnt > 0)
  [ set comp-mean-rtrn mean [cust-rtrn] of my-cust ]
  [ set comp-mean-rtrn 0 ]
end

to end-qtr

end

to cust-move
  ifelse (cust-comp-id = -1)
  [
    rt random 30 - random 60
    fd random-float attract
  ]
  [ ifelse (cust-happy > -1)
    [
      face company cust-comp-id
      fd random-float attract
    ]
    [
      face company cust-comp-id
      bk random-float repel
    ]
  ]
end

to comp-set-loc
  setxy ((random-float (world-width - 2)) + 1)
  ((random-float (world-height - 2)) + 1)
end

to-report vary-rate [ rate-min rate-max ]
  report rate-min + random-float (rate-max - rate-min)
end
