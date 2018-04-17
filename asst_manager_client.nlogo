globals [
  quarter
  colors
  color-names
  num-colors
  used-colors
  n/a
]

breed [ companies company ]
breed [ customers customer ]

patches-own [ ]

customers-own [
  my-company
  cust-money
]

companies-own [
  company-user-id
  comp-profit
  comp-price
  comp-cost
  comp-type
]

to setup

  clear-patches
  clear-turtles
  clear-output
  setup-globals
  setup-companies
  setup-customers
  clear-all-plots
  ask companies [ reset-company-variables ]

end

to setup-globals

  reset-ticks

  set quarter 0
  set-default-shape customers "face happy"
  set colors [
    lime orange brown yellow turquoise cyan sky blue
    violet magenta pink red green gray 12 62 102 38
  ]
  set color-names [
    "lime" "orange" "brown" "yellow" "turquoise" "cyan" "sky" "blue"
    "violet" "magenta" "pink" "red" "green" "gray" "maroon" "hunter green" "navy" "sand"
  ]
  set used-colors []
  set num-colors length colors
  set n/a "n/a"

end

to setup-customers

  create-customers num-customers [
    setxy random-xcor random-ycor
    set shape "face happy"
    set color lime
    set size .5

    let chance random 3

    ifelse (chance = 0)
    [ set color pink ]
    [ ifelse (chance = 1)
      [set color yellow]
      [set color blue]
    ]

    set cust-money random (initial-principal) * 1000
  ]

end

to setup-companies

  create-companies num-companies [
    set company-user-id who
    set size 2

    let chance random 3

    ifelse (chance = 0)
    [ set color red
      set shape "circle"
      set comp-type "AAA"]
    [ ifelse (chance = 1)
      [ set color lime
        set shape "triangle"
        set comp-type "BBB"]
      [ set color 38
        set shape "square"
        set comp-type "CCC"]
    ]

    set comp-price random 5
    set comp-cost (variable-cost + return-cost + fixed-cost)

    setup-company-location
  ]

end

to go
  ask companies [
    make-profit
    attract-customers ]
  ask customers [
    move-customers ]

  set quarter quarter + 1

  tick
end

to make-profit
  let comp# company-user-id

  ask customers with [ my-company = comp# ]
  [ set cust-money cust-money * (1 + (desired-return * (-1 * exp 10))) ]

  set comp-profit ((comp-price * count-num-customer) - comp-cost)
end

to attract-customers

end

to setup-company-location

  setxy (random (world-width * .75))
  (random (world-height * .75))
  if any? other companies in-radius 3
  [ setup-company-location ]

end

to move-customers

  fd 1

end

to plot-company-statistics
  set-current-plot "Profits"
  set-current-plot-pen "avg-profit"
  plot mean [comp-profit] of companies
end

to-report count-num-customer
  let num-cust 0
  let comp# company-user-id

  ask customers with [my-company = comp#]
  [
    set num-cust (num-cust + 1)
  ]

  report num-cust
end

to-report AAA-types
  report count companies with [ comp-type = "AAA" ]
end

to-report BBB-types
  report count companies with [ comp-type = "BBB" ]
end

to-report CCC-types
  report count companies with [ comp-type = "CCC" ]
end

to end-quarters

end

to reset-company-variables

end

to-report avg-profit/companyes

end

to test-happiness

end
