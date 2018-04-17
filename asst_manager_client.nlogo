;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
  quarter                  ;; number of quarters so far
  colors
  color-names
  num-colors
  used-colors
  n/a
]

patches-own [ ]

breed [ companies company ]
breed [ customers customer ]

customers-own [
  ;; Customer Preferences
  customer-risk-preference        ;; investment type
  customer-desired-return          ;; desired return rate

  customer-money
  customer-quarter-return
  customer-quarter-profit

  customer-spending-threshold  ;; the maximum amount of money the customer can spend

  ;; company Appeal
  appeal               ;; how appealing the company is to the customer
  persuaded?           ;; has the customer been persuaded to go to a company
  my-company           ;; by which company has the customer been persuaded
  customer-satisfaction
  unhappy-counter ;; number of consecutive unhappy quarters

  customer-initial-principal
]

companies-own [
  ;; firm Information
  user-id              ;; unique user-id, input by the client when they log in, to identify each student's company
  auto?                ;; is the firm automated
  bankrupt?            ;; is the firm bankrupt
  account-balance      ;; total amount of money the firm has

  ;; Ranking Statistics
  received-rank?       ;; if given a rank, ranked? is true, otherwise false
  rank                 ;; rank number according to account balance

  ;; company Information
  company-color        ;; color of the company

  ;; company risk Profile
  company-type      ;; the type of type the company serves
  company-service      ;; the quality of the service
  company-value      ;; the value of the asset manager
  company-management-fee        ;; the management-fee of the company
  company-minimum-investment

  ;; company Statistics
  quarters-revenue         ;; amount of revenue generated so far to current quarter
  quarters-cost            ;; amount of costs accumulated so far to current quarter
  quarters-profit          ;; profit made so far to current quarter
  num-customers        ;; number of customers to current quarter
  profit-customer  ;; avg profit made per customer
]

to setup
  clear-patches
  clear-turtles
  clear-output
  reset
end

to reset
  setup-globals
  setup-companies num-companies ;; slide bard variable
  setup-customers
  clear-all-plots
  ask companies
  [ reset-firm-variables ]
end

to setup-globals
  reset-ticks
  set quarter 0

  set-default-shape customers "face happy"

  ;; Set the available colors  and their names
  set colors      [ lime   orange   brown   yellow  turquoise  cyan   sky   blue
    violet   magenta   pink  red  green  gray  12 62 102 38 ]
  set color-names ["lime" "orange" "brown" "yellow" "turquoise" "cyan" "sky" "blue"
    "violet" "magenta" "pink" "red" "green" "gray" "maroon" "hunter green" "navy" "sand"]
  set used-colors []
  set num-colors length colors
  set n/a "n/a"
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customer Setup Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-customers

  ask customers
  [ die ]

  create-customers num-customer
  [ set customer-initial-principal ((random initial-principal) * 10) ;; set initially given principal
    set persuaded? false
    set my-company -1

    setxy random-xcor random-ycor

    set appeal 0
    let chance random 3
    set size 0.5

    ;; initialize the customer's preferences
    set customer-money customer-initial-principal
    set customer-quarter-profit 0
    set customer-quarter-return 0

    set customer-desired-return (random-float desired-return)
    set customer-satisfaction false
    set unhappy-counter 0

    ifelse (chance = 0)
    [ set color red
      set customer-risk-preference "AAA" ]
    [ ifelse (chance = 1)
      [ set color yellow
        set customer-risk-preference "BBB" ]
      [ set color cyan
        set customer-risk-preference "CCC" ] ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Automated companies Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-companies [ number ]
  create-companies number
  [ set user-id who
    reset-firm-variables
    set auto? true
    set size 2
    setup-automated-company
    setup-location ]
end

to setup-automated-company

  let chance (random 3)
  set company-service (50 + random 50)
  set company-value (50 + random 50)
  set company-management-fee ((company-value / 2) + random 50)
  ifelse (chance = 0)
  [ set company-type "AAA"
    set shape "circle"
    set color random 50 ]
  [ ifelse (chance = 1)
    [ set company-type "BBB"
      set shape "triangle"
      set color random 50 ]
    [ set company-type "CCC"
      set shape "square"
      set color random 50 ] ]
end

to go
  ask companies with [ bankrupt? = false ] ;; Let the companies work
  [ serve-customers
    attract-customers ]

  ask customers ;; Move the customers
  [ move-customers ]

  if (ticks mod quarter-length) = 0 ;; Is it time to end the quarter?
  [ set quarter quarter + 1
    plot-disgruntled-customers
    plot-company-statistics
    ask companies with [ bankrupt? = false ]
    [ end-quarter ]
    if show-rank? and any? companies with [auto? = false]
    [ rank-companies ] ]
  tick
end

to serve-customers ;; turtle procedure
  let company# user-id
  let new-customers 0
  let comp-price company-management-fee

  ;; customers update the information of the company where they have decided to dine
  ask customers with [ (persuaded? = true) and (my-company = company#) ] in-radius 1
  [ set new-customers new-customers + 1
    set persuaded? false
    ; set my-company -1
    set appeal 0
    set customer-quarter-return customer-money * (customer-desired-return - (random-float (desired-return / 2)))
    set customer-money customer-money + customer-quarter-return
    set customer-quarter-profit (customer-quarter-return - comp-price)

  	test-happiness ]

  set num-customers (num-customers + new-customers)
  set quarters-revenue (quarters-revenue + (new-customers * company-management-fee))
  set quarters-cost round (quarters-cost + (new-customers * variable-cost * company-service) + (new-customers * return-cost * company-value))
  set quarters-profit round (quarters-revenue - quarters-cost)
end

to attract-customers ;; turtle procedure
  let company# user-id
  let r-x xcor
  let r-y ycor
  let r-type company-type
  let adj-management-fee (company-management-fee - 0.15 * company-service)
  let adj-value (company-value + 0.15 * company-service)
  let util-management-fee false
  let util-value false
  let company-appeal false

  ask customers with [ (customer-money > 0) and (customer-risk-preference = r-type) ] in-radius 7
  [
    set util-management-fee (customer-money - adj-management-fee)
    set util-value (adj-value - (customer-desired-return * 100))
    if (util-management-fee >= 0) and (util-value >= 0)
    [
      set company-appeal (util-management-fee + util-value) * 5
      if (company-appeal > appeal)
      [ set appeal company-appeal
        set persuaded? true
        set my-company company#
        facexy r-x r-y ] ] ]
end

to setup-location
  setxy ((random (world-width - 2)) + 1)
  ((random (world-height - 2)) + 1)
  if any? other companies in-radius 3
  [ setup-location ]
end

to move-customers
  ; if persuaded? = false
  ; [ rt random-float 45 - random-float 45 ]
  set customer-money customer-money * ( 1 - loss-rate)
  fd 1
end

to test-happiness

  ifelse (mean [customer-quarter-profit] of customers <= customer-quarter-profit)
  [ set customer-satisfaction true
    set unhappy-counter 0]
  [	set customer-satisfaction false
    set unhappy-counter (unhappy-counter + 1) ]

end

to end-quarter
  set account-balance round (account-balance + quarters-profit)
  set quarters-cost fixed-cost
  set quarters-revenue 0
  set quarters-profit (quarters-revenue - quarters-cost)
  set num-customers 0

  if (bankruptcy?) ;; If the firm is bankrupt shut his company down
  [ if (account-balance < 0)
    [ set bankrupt? true ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Ranking Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

to rank-companies
  let num-ranks (length (remove-duplicates ([account-balance] of companies)))
  let rank# count companies

  repeat num-ranks
  [ let min-rev min [account-balance] of companies with [not received-rank?]
    let rankee companies with [account-balance = min-rev]
    let num-tied count rankee
    ask rankee
    [ set rank rank#
      set received-rank? true ]
    set rank# rank# - num-tied ]

  ask companies
  [ set received-rank? false ]
end


to plot-disgruntled-customers
  set-current-plot "Disgruntled Customers"
  plot disgruntled-customers
end

to plot-company-statistics
  ask companies with [ auto? = false ]
  [ set-current-plot "Profits"
    set-current-plot-pen user-id
    plot quarters-profit

    set-current-plot "# Customers"
    set-current-plot-pen user-id
    plot num-customers
  ]

  set-current-plot "Profits"
  set-current-plot-pen "avg-profit"
  plot mean [quarters-profit] of companies

  set-current-plot "# Customers"
  set-current-plot-pen "avg-custs"
  plot mean [num-customers] of companies

  set-current-plot "Customer Satisfaction"
  set-current-plot-pen "min."
  plot min [appeal] of customers
  set-current-plot-pen "avg."
  plot mean [appeal] of customers
  set-current-plot-pen "max."
  plot max [appeal] of customers
end

to-report AAA-types
  report count companies with [ company-type = "AAA" ]
end

to-report BBB-types
  report count companies with [ company-type = "BBB" ]
end

to-report CCC-types
  report count companies with [ company-type = "CCC" ]
end

to-report avg-profit/firm
  report mean [ quarters-profit ] of companies
end

to-report avg-customers/firm
  report mean [ num-customers ] of companies
end

to-report avg-customer-initial-principal/customer
  report mean [ customer-initial-principal ] of customers
end

to-report disgruntled-customers
  report count customers with [ unhappy-counter > 0 ]
end

to-report avg-unhappy
  report mean [ unhappy-counter ] of customers
end

to reset-firm-variables
  set rank n/a
  set received-rank? false
  set bankrupt? false
  set account-balance 2000
  set quarters-revenue 0
  set quarters-cost fixed-cost
  set quarters-profit 0
  set profit-customer 100
  set num-customers 0
  set company-management-fee random 50
  set company-service 50 + random 50
  set company-value 50 + random 50
end

;; returns string version of color name
to-report color->string [ color-value ]
  report item (position color-value colors) color-names
end
