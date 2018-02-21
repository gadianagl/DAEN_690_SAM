;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
 day                  ;; number of days so far

 ;; Color globals
 colors               ;; list that holds the colors for the student's asset-manager
 color-names          ;; list that holds the names of the colors used for the student's asset-managers
 num-colors           ;; number of different colors in the color list
 used-colors          ;; list that holds the colors that are already being used

 ;; quick start instructions variables
 quick-start          ;; current quickstart instruction displayed in the quickstart monitor
 qs-item              ;; index of the current quickstart instruction
 qs-items             ;; list of quickstart instructions

 n/a                  ;; unset variable indicator
]

patches-own [ ]

breed [ asset-managers asset-manager ]         ;; controlled by the clients
breed [ customers customer ]             ;; created by the server

customers-own [
 ;; Customer Preferences
 customer-type        ;; the preferred type type
 customer-risk          ;; the preferred risk of the type
 customer-money          ;; the maximum amount of money the customer can spend

 ;; asset-manager Appeal
 appeal               ;; how appealing the asset-manager is to the customer
 persuaded?           ;; has the customer been persuaded to go to a asset-manager
 my-asset-manager           ;; by which asset-manager has the customer been persuaded

 ;; Eating Patterns
 motive               ;; amount of motive the customer has
]

asset-managers-own [
 ;; firm Information
 user-id              ;; unique user-id, input by the client when they log in, to identify each student's asset-manager
 auto?                ;; is the firm automated
 bankrupt?            ;; is the firm bankrupt
 account-balance      ;; total amount of money the firm has

 ;; Ranking Statistics
 received-rank?       ;; if given a rank, ranked? is true, otherwise false
 rank                 ;; rank number according to account balance

 ;; asset-manager Information
 asset-manager-color        ;; color of the asset-manager

 ;; asset-manager risk Profile
 asset-manager-type      ;; the type of type the asset-manager serves
 asset-manager-service      ;; the risk of the service
 asset-manager-risk      ;; the risk of the food
 asset-manager-price        ;; the price of a meal at the asset-manager

 ;; asset-manager Statistics
 days-revenue         ;; amount of revenue generated so far to current day
 days-cost            ;; amount of costs accumulated so far to current day
 days-profit          ;; profit made so far to current day
 num-customers        ;; number of customers to current day
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
  setup-asset-managers #auto-asset-managers
  setup-consumers
  clear-all-plots
  ask asset-managers
  [ reset-firm-variables ]
end

to setup-globals
  reset-ticks
  set day 0

  set-default-shape customers "person"

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

to setup-consumers

  ask customers
  [ die ]

  create-customers num-consumer
    [ set motive consumer-motive
    set persuaded? false
    set my-asset-manager -1

    setxy random-xcor random-ycor

    set appeal 0
    let chance random 3

    ;; initialize the customer's preferences
    set customer-money (20 + random 81)
    set customer-risk (customer-money - 20)
    ifelse (chance = 0)
    [ set color red
      set customer-type "AAA" ]
    [ ifelse (chance = 1)
      [ set color yellow
        set customer-type "BBB" ]
      [ set color cyan
        set customer-type "CCC" ] ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Automated asset-managers Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-asset-managers [ number ]
  create-asset-managers number
  [ set user-id who
    reset-firm-variables
    set auto? true
    set color 32
    set size 2
    setup-automated-asset-manager
    setup-location ]
end

to setup-automated-asset-manager

  let chance (random 3)
  set asset-manager-service 5
  set asset-manager-risk (25 + random 50)
  set asset-manager-price (asset-manager-risk + 10)
  ifelse (chance = 0)
  [ set asset-manager-type "AAA"
    set shape "circle" ]
  [ ifelse (chance = 1)
    [ set asset-manager-type "BBB"
      set shape "triangle" ]
    [ set asset-manager-type "CCC"
      set shape "square" ] ]
end

to go
  ask asset-managers with [ bankrupt? = false ] ;; Let the asset-managers work
  [ serve-customers
    attract-customers ]

  ask customers ;; Move the customers
  [ move-customers ]

  if (ticks mod day-length) = 0 ;; Is it time to end the day?
  [ set day day + 1
   plot-disgruntled-customers
   plot-asset-manager-statistics
   ask asset-managers with [ bankrupt? = false ]
   [ end-day ]
   if show-rank? and any? asset-managers with [auto? = false]
    [ rank-asset-managers ] ]
  tick
end

to serve-customers ;; turtle procedure
 let asset-manager# user-id
 let new-customers 0

 ;; customers update the information of the asset-manager where they have decided to dine
 ask customers with [ (persuaded? = true) and (my-asset-manager = asset-manager#) ] in-radius 1
 [ set new-customers new-customers + 1
   set persuaded? false
   set my-asset-manager -1
   set appeal 0
   set motive consumer-motive ]

  set num-customers (num-customers + new-customers)
  set days-revenue (days-revenue + (new-customers * asset-manager-price))
  set days-cost round (days-cost + (new-customers * service-cost * asset-manager-service) + (new-customers * risk-cost * asset-manager-risk))
  set days-profit round (days-revenue - days-cost)
end

to attract-customers ;; turtle procedure
  let asset-manager# user-id
  let r-x xcor
  let r-y ycor
  let r-type asset-manager-type
  let adj-price (asset-manager-price - 0.15 * asset-manager-service)
  let adj-risk (asset-manager-risk + 0.15 * asset-manager-service)
  let util-price false
  let util-risk false
  let asset-manager-appeal false

  ask customers with [ (motive < consumer-threshold) and (customer-type = r-type) ] in-radius 7
  [
    set util-price (customer-money - adj-price)
    set util-risk (adj-risk - customer-risk)
    if (util-price >= 0) and (util-risk >= 0)
    [
       set asset-manager-appeal (util-price + util-risk) * 5
       if (asset-manager-appeal > appeal)
       [ set appeal asset-manager-appeal
         set persuaded? true
         set my-asset-manager asset-manager#
         facexy r-x r-y ] ] ]
end

to setup-location
  setxy ((random (world-width - 2)) + 1)
        ((random (world-height - 2)) + 1)
  if any? other asset-managers in-radius 3
  [ setup-location ]
end

to move-customers
 if persuaded? = false
 [ rt random-float 45 - random-float 45 ]
 set motive motive - 1
 fd 1
end

to end-day 
  set account-balance round (account-balance + days-profit)
  set days-cost operation-cost
  set days-revenue 0
  set days-profit (days-revenue - days-cost)
  set num-customers 0

  if (bankruptcy?) ;; If the firm is bankrupt shut his asset-manager down
  [ if (account-balance < 0)
  [ set bankrupt? true ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Ranking Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

to rank-asset-managers
  let num-ranks (length (remove-duplicates ([account-balance] of asset-managers)))
  let rank# count asset-managers

  repeat num-ranks
  [ let min-rev min [account-balance] of asset-managers with [not received-rank?]
    let rankee asset-managers with [account-balance = min-rev]
    let num-tied count rankee
    ask rankee
    [ set rank rank#
      set received-rank? true ]
    set rank# rank# - num-tied ]

  ask asset-managers
  [ set received-rank? false ]
end


to plot-disgruntled-customers
  set-current-plot "Disgruntled Customers"
  plot disgruntled-consumers
end

to plot-asset-manager-statistics
    ask asset-managers with [ auto? = false ]
    [ set-current-plot "Profits"
      set-current-plot-pen user-id
      plot days-profit

      set-current-plot "# Customers"
      set-current-plot-pen user-id
      plot num-customers
    ]

    set-current-plot "Profits"
    set-current-plot-pen "avg-profit"
    plot mean [days-profit] of asset-managers

    set-current-plot "# Customers"
    set-current-plot-pen "avg-custs"
    plot mean [num-customers] of asset-managers

    set-current-plot "Customer Satisfaction"
    set-current-plot-pen "min."
    plot min [appeal] of customers
    set-current-plot-pen "avg."
    plot mean [appeal] of customers
    set-current-plot-pen "max."
    plot max [appeal] of customers
end

to-report AAA-types
  report count asset-managers with [ asset-manager-type = "AAA" ]
end

to-report BBB-types
  report count asset-managers with [ asset-manager-type = "BBB" ]
end

to-report CCC-types
  report count asset-managers with [ asset-manager-type = "CCC" ]
end

to-report avg-profit/firm
  report mean [ days-profit ] of asset-managers
end

to-report avg-customers/firm
  report mean [ num-customers ] of asset-managers
end

to-report avg-motive/customer
  report mean [ motive ] of customers
end

to-report disgruntled-consumers
  report count customers with [ motive < 0 ]
end

to reset-firm-variables
  set rank n/a
  set received-rank? false
  set bankrupt? false
  set account-balance 2000
  set days-revenue 0
  set days-cost operation-cost
  set days-profit 0
  set profit-customer 100
  set num-customers 0
  set asset-manager-price random 50
  set asset-manager-service 50 + random 50
  set asset-manager-risk 50 + random 50
end

;; returns string version of color name
to-report color->string [ color-value ]
  report item (position color-value colors) color-names
end
