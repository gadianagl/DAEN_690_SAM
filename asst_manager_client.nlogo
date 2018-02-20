;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [
 day                  ;; number of days so far

 ;; Color globals
 colors               ;; list that holds the colors for the student's asset_manager
 color-names          ;; list that holds the names of the colors used for the student's asset_managers
 num-colors           ;; number of different colors in the color list
 used-colors          ;; list that holds the colors that are already being used

 ;; quick start instructions variables
 quick-start          ;; current quickstart instruction displayed in the quickstart monitor
 qs-item              ;; index of the current quickstart instruction
 qs-items             ;; list of quickstart instructions

 n/a                  ;; unset variable indicator
]

patches-own [ ]

breed [ asset_managers asset_manager ]         ;; controlled by the clients
breed [ customers customer ]             ;; created by the server

customers-own [
 ;; Customer Preferences
 customer-cash        ;; the preferred cuisine type
 customer-risk          ;; the preferred quality of the cuisine
 customer-return          ;; the maximum amount of money the customer can spend on a meal

 ;; asset_manager Appeal
 appeal               ;; how appealing the asset_manager is to the customer
 persuaded?           ;; has the customer been persuaded to go to a asset_manager
 my-asset_manager           ;; by which asset_manager has the customer been persuaded

 ;; Eating Patterns
 energy               ;; amount of energy the customer has
]

asset_managers-own [
 ;; Owner Information
 user-id              ;; unique user-id, input by the client when they log in, to identify each student's asset_manager
 auto?                ;; is the owner automated
 bankrupt?            ;; is the owner bankrupt
 account-balance      ;; total amount of money the owner has

 ;; Ranking Statistics
 received-rank?       ;; if given a rank, ranked? is true, otherwise false
 rank                 ;; rank number according to account balance

 ;; asset_manager Information
 asset_manager-color        ;; color of the asset_manager

 ;; asset_manager Taste Profile
 asset_manager-cuisine      ;; the type of cuisine the asset_manager serves
 asset_manager-service      ;; the quality of the service
 asset_manager-quality      ;; the quality of the food
 asset_manager-price        ;; the price of a meal at the asset_manager

 ;; asset_manager Statistics
 days-revenue         ;; amount of revenue generated so far today
 days-cost            ;; amount of costs accumulated so far today
 days-profit          ;; profit made so far today
 num-customers        ;; number of customers today
 profit-customer  ;; avg profit made per customer
]

;;;;;;;;;;;;;;;;;;;;;
;; Setup Functions ;;
;;;;;;;;;;;;;;;;;;;;;

to startup
  hubnet-reset
  setup
end

;; initializes the display and
;; set parameters for the system
to setup
  clear-patches
  clear-turtles
  clear-output
  setup-quick-start
  reset
end

;; initializes the display (but does not clear already created asset_managers)
to reset
  setup-globals
  setup-consumers
  clear-all-plots
  ask asset_managers
  [ reset-owner-variables ]
  broadcast-system-info
end

;; initializes the global variables
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

;; initializes and creates the customers
to setup-consumers

  ask customers
  [ die ]

  create-customers num-consumer
    [ set energy consumer-energy
    set persuaded? false
    set my-asset_manager -1

    setxy random-xcor random-ycor

    set appeal 0
    let chance random 3

    ;; initialize the customer's preferences
    set customer-money (20 + random 81)
    set customer-taste (customer-money - 20)
    ifelse (chance = 0)
    [ set color red
      set customer-cuisine "American" ]
    [ ifelse (chance = 1)
      [ set color yellow
        set customer-cuisine "Asian" ]
      [ set color cyan
        set customer-cuisine "European" ] ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Automated asset_managers Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; creates automated owners
to create-automated-asset_managers [ number ]
  create-asset_managers number
  [ set user-id who
    reset-owner-variables
    set auto? true
    set color 32
    set size 2
    setup-automated-asset_manager
    setup-location ]
end

;; initializes the automated owner's variables
to setup-automated-asset_manager

  let chance (random 3)

  ;; initializes the automated owner's settings
  set asset_manager-service 5
  set asset_manager-quality (25 + random 50)
  set asset_manager-price (asset_manager-quality + 10)
  ifelse (chance = 0)
  [ set asset_manager-cuisine "American"
    set shape "asset_manager american" ]
  [ ifelse (chance = 1)
    [ set asset_manager-cuisine "Asian"
      set shape "asset_manager asian" ]
    [ set asset_manager-cuisine "European"
      set shape "asset_manager european" ] ]
end

;;;;;;;;;;;;;;;;;;
;; Setup Prompt ;;
;;;;;;;;;;;;;;;;;;

;; give the user some information about what the setup button does so they can
;; know whether they want to proceed before actually doing the setup
to setup-prompt
 if user-yes-or-no? (word "The SETUP button should only be used when starting "
             "over with a new group (such as a new set of students) since "
             "all data is lost.  Use the RE-RUN button for continuing with "
             "an existing group."
             "\n\nDo you really want to setup the model?")
 [ user-message (word "Before closing this dialog, please do the following:"
                "\n  -Have everyone that is currently logged in, log off and "
                "then kick all remaining clients with the HubNet Console.")
   setup ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  listen-to-clients
  every .5
  [ broadcast-system-info
    ask asset_managers with [ auto? = false ]
    [ send-personal-info ] ]

  if not any? asset_managers
  [ user-message "There are no asset_manager owners. Log people in or create asset_managers."
    stop ]

  ask asset_managers with [ bankrupt? = false ] ;; Let the asset_managers work
  [ serve-customers
    attract-customers ]

  ask customers ;; Move the customers
  [ move-customers ]

  if (ticks mod day-length) = 0 ;; Is it time to end the day?
  [ set day day + 1
   plot-disgruntled-customers
   plot-asset_manager-statistics
   ask asset_managers with [ bankrupt? = false ]
   [ end-day ]
   if show-rank? and any? asset_managers with [auto? = false]
    [ rank-asset_managers ] ]
  tick
end

to serve-customers ;; turtle procedure
 let asset_manager# user-id
 let new-customers 0

 ;; customers update the information of the asset_manager where they have decided to dine
 ask customers with [ (persuaded? = true) and (my-asset_manager = asset_manager#) ] in-radius 1
 [ set new-customers new-customers + 1
   set persuaded? false
   set my-asset_manager -1
   set appeal 0
   set energy consumer-energy ]

  set num-customers (num-customers + new-customers)
  set days-revenue (days-revenue + (new-customers * asset_manager-price))
  set days-cost round (days-cost + (new-customers * service-cost * asset_manager-service) + (new-customers * quality-cost * asset_manager-quality))
  set days-profit round (days-revenue - days-cost)
end

to attract-customers ;; turtle procedure
  let asset_manager# user-id
  let r-x xcor
  let r-y ycor
  let r-cuisine asset_manager-cuisine
  let adj-price (asset_manager-price - 0.15 * asset_manager-service)
  let adj-quality (asset_manager-quality + 0.15 * asset_manager-service)
  let util-price false
  let util-quality false
  let asset_manager-appeal false

  ;; Try and persuade customers that are within range
  ask customers with [ (energy < consumer-threshold) and (customer-cuisine = r-cuisine) ] in-radius 7
  [
    set util-price (customer-money - adj-price)
    set util-quality (adj-quality - customer-taste)
    if (util-price >= 0) and (util-quality >= 0)
    [
       set asset_manager-appeal (util-price + util-quality) * 5
       if (asset_manager-appeal > appeal)
       [ set appeal asset_manager-appeal
         set persuaded? true
         set my-asset_manager asset_manager#
         facexy r-x r-y ] ] ]
end

;; makes the customers move
to move-customers ;; customer procedure
 if persuaded? = false
 [ rt random-float 45 - random-float 45 ]
 set energy energy - 1
 fd 1
end

;; makes the owner calculate end-of-day figures and initializes
;; the personal variables for the next day
to end-day ;; turtle procedure

  if (auto? = false)
  [ hubnet-send user-id "Number of Customers" num-customers
    hubnet-send user-id "Day's Profit" days-profit
    hubnet-send user-id "Day's Revenue" days-revenue
    hubnet-send user-id "Day's Cost" days-cost ]

  set account-balance round (account-balance + days-profit)
  set days-cost rent-cost
  set days-revenue 0
  set days-profit (days-revenue - days-cost)
  set num-customers 0

  if (bankruptcy?) ;; If the owner is bankrupt shut his asset_manager down
  [ if (account-balance < 0)
  [ set bankrupt? true ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Ranking Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

;; ranks owners by their account balance. if there are three players and two of them are tied with the
;; lower account balance, then they will both be ranked as 3rd place.
to rank-asset_managers
  let num-ranks (length (remove-duplicates ([account-balance] of asset_managers)))
  let rank# count asset_managers

  repeat num-ranks
  [ let min-rev min [account-balance] of asset_managers with [not received-rank?]
    let rankee asset_managers with [account-balance = min-rev]
    let num-tied count rankee
    ask rankee
    [ set rank rank#
      set received-rank? true ]
    set rank# rank# - num-tied ]

  ask asset_managers
  [ set received-rank? false ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;; Plotting Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; plot the number of disgruntled customers
to plot-disgruntled-customers
  set-current-plot "Disgruntled Customers"
  plot disgruntled-consumers
end

;; plot the asset_manager statistics for the user controlled asset_managers
to plot-asset_manager-statistics
    ask asset_managers with [ auto? = false ]
    [ set-current-plot "Profits"
      set-current-plot-pen user-id
      plot days-profit

      set-current-plot "# Customers"
      set-current-plot-pen user-id
      plot num-customers
    ]

    set-current-plot "Profits"
    set-current-plot-pen "avg-profit"
    plot mean [days-profit] of asset_managers

    set-current-plot "# Customers"
    set-current-plot-pen "avg-custs"
    plot mean [num-customers] of asset_managers

    set-current-plot "Customer Satisfaction"
    set-current-plot-pen "min."
    plot min [appeal] of customers
    set-current-plot-pen "avg."
    plot mean [appeal] of customers
    set-current-plot-pen "max."
    plot max [appeal] of customers
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculation Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; reports the number of tavern asset_managers in the marketplace
to-report american-cuisines
  report count asset_managers with [ asset_manager-cuisine = "American" ]
end

;; reports the number of fine dining asset_managers in the marketplace
to-report asian-cuisines
  report count asset_managers with [ asset_manager-cuisine = "Asian" ]
end

;; reports the number of fast food asset_managers in the marketplace
to-report european-cuisines
  report count asset_managers with [ asset_manager-cuisine = "European" ]
end

;; reports the avg profit from all the owners on the current day
to-report avg-profit/owner
  report mean [ days-profit ] of asset_managers
end

to-report avg-customers/owner
  report mean [ num-customers ] of asset_managers
end

;; reports the avg energy of the customers
to-report avg-energy/customer
  report mean [ energy ] of customers
end

;; reports the number of customers that can't find a asset_manager that they want to eat at
to-report disgruntled-consumers
  report count customers with [ energy < 0 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Quick Start functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; instructions to quickly setup the model, and clients to run this activity
to setup-quick-start
  set qs-item 0
  set qs-items
  [ "Teacher: Follow these directions to run the HubNet activity."
    "Press the SETUP button, then Press the INITIAL LOGIN button."
    "Everyone: Open up a HubNet Client on your machine, input the IP Address of this computer, press ENTER, type your name, and press ENTER."
    "Teacher: Once everyone has logged in, turn off the INITIAL LOGIN button by pressing it again."
    "Have the students acquaint themselves with their interface."
    "Teacher: Press GO to start the simulation."
    "Each student is a restaurateur. The customers are independent computer agents."
    "Following are some additional features you might want to adjust for later runs:"
    "NUM-CUSTOMERS determines the number of customers: set this before you run the game."
    "The following conditions can be changed either before or while the game is running:"
    "If SHOW-RANK? is on, the students are able to see their ranking amongst all restaurateurs."
    "If BANKRUPCY? is on, then students might go bankrupt."
    "Use the cost sliders, QUALITY-COST, SERVICE-COST and RENT-COST to adjust costs."
    "CUSTOMER-ENERGY determines the beginning energy of the customer."
    "CUSTOMER-THRESHOLD determines the threshold at which a customer gets hungry."
    "To create some automated asset_managers set the AUTO-asset_managers slider and press CREATE-AUTOMATED-asset_managers."
    "Teacher: To rerun the activity with the same group, un-press GO, adjust settings, press RE-RUN then GO."
    "Teacher: To start the simulation over with a new group, follow our instruction set again."]
  set quick-start (item qs-item qs-items)
end

;; view the next item in the quickstart monitor
to view-next
  set qs-item qs-item + 1
  if qs-item >= length qs-items
  [ set qs-item length qs-items - 1 ]
  set quick-start (item qs-item qs-items)
end

;; view the previous item in the quickstart monitor
to view-prev
  set qs-item qs-item - 1
  if qs-item < 0
  [ set qs-item 0 ]
  set quick-start (item qs-item qs-items)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Code for interacting with the clients ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; determines which client sent a command, and what the command was
to listen-to-clients
  while [ hubnet-message-waiting? ]
  [ hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-asset_manager hubnet-message-source ]
    [ ifelse hubnet-exit-message?
      [ remove-asset_manager hubnet-message-source ]
      [ execute-command hubnet-message-tag ] ] ]
end

;; NetLogo knows what each student's asset_manager patch is supposed to be
;; doing based on the tag sent by the name Cuisine, Service, Price and Quality
to execute-command [command]
  if command = "Cuisine"
  [ ask asset_managers with [ user-id = hubnet-message-source ]
    [ set asset_manager-cuisine hubnet-message
      ifelse (asset_manager-cuisine = "American")
      [ set shape "asset_manager american" ]
      [ ifelse (asset_manager-cuisine = "Asian")
        [ set shape "asset_manager asian" ]
        [ set shape "asset_manager european" ] ] ]
    stop ]
  if command = "Service"
  [ ask asset_managers with [ user-id = hubnet-message-source ]
    [ set asset_manager-service hubnet-message
      set profit-customer round (asset_manager-price - ((service-cost * asset_manager-service) + (quality-cost * asset_manager-quality))) ]
    stop ]
  if command = "Quality"
  [ ask asset_managers with [ user-id = hubnet-message-source ]
    [ set asset_manager-quality hubnet-message
      set profit-customer round (asset_manager-price - ((service-cost * asset_manager-service) + (quality-cost * asset_manager-quality))) ]
    stop ]
  if command = "Price"
  [ ask asset_managers with [ user-id = hubnet-message-source ]
    [ set asset_manager-price hubnet-message
      set profit-customer round (asset_manager-price - ((service-cost * asset_manager-service) + (quality-cost * asset_manager-quality))) ]
    stop ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Owner Setup Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; creates a new owner
to create-new-asset_manager [ id ]
  create-asset_managers 1
  [ set user-id id
    set auto? false
    reset-owner-variables
    setup-asset_manager
    setup-location
    send-personal-info
  ]
end

;; sets up the owners personal variables and location
to setup-asset_manager ;; asset_manager procedure
  let helplist remove used-colors colors

  ifelse empty? helplist
  [set asset_manager-color one-of colors ]
  [
   set asset_manager-color one-of helplist
   set used-colors lput asset_manager-color used-colors
  ]
  set color asset_manager-color
  set size 2
  set shape one-of ["asset_manager american" "asset_manager asian" "asset_manager european" ]
  ifelse shape = "asset_manager american"
  [set asset_manager-cuisine "American"]
  [
   ifelse shape = "asset_manager asian"
   [set asset_manager-cuisine "Asian"]
   [set asset_manager-cuisine "European"]
  ]
  reset-owner-variables
end

;; sets up the asset_manager's location and premises
to setup-location   ;; owner procedure
  setxy ((random (world-width - 2)) + 1)
        ((random (world-height - 2)) + 1)
  if any? other asset_managers in-radius 3
  [ setup-location ]
end

;; reset owners variables to initial values
to reset-owner-variables  ;; owner procedure
  set rank n/a
  set received-rank? false
  set bankrupt? false
  set account-balance 2000
  set days-revenue 0
  set days-cost rent-cost
  set days-profit 0
  set profit-customer 100
  set num-customers 0
  set asset_manager-price random 50
  set asset_manager-service 50 + random 50
  set asset_manager-quality 50 + random 50
  if (auto? = false) ;; send the personal info only to clients
  [ send-personal-info ]
  ask asset_managers with [auto? = false]
  [
    ;; Setup the plot pens for the asset_manager
    set-current-plot "Profits"
    create-temporary-plot-pen user-id
    set-plot-pen-color asset_manager-color

    set-current-plot "# Customers"
    create-temporary-plot-pen user-id
    set-plot-pen-color asset_manager-color
  ]
end

;; delete asset_manager once client has exited
to remove-asset_manager [ id ] ;; owner procedure
  let old-color false
  ask asset_managers with [user-id = id] ;; remove the owner's turtle
  [ set old-color asset_manager-color
    die ]

  if not any? asset_managers with [ color = old-color ] ;; make the unused color available again
  [ set used-colors remove (position old-color colors) used-colors ]
end

;; sends the appropriate monitor information back to the client
to send-personal-info ;; asset_manager procedure
  hubnet-send user-id "asset_manager Color" (color->string color)
  hubnet-send user-id "Account Balance" account-balance
  hubnet-send user-id "Profit / Customer" profit-customer
  hubnet-send user-id "Rank" rank
  hubnet-send user-id "Bankrupt?" bankrupt?
  hubnet-send user-id "Cuisine" asset_manager-cuisine
  hubnet-send user-id "Service" asset_manager-service
  hubnet-send user-id "Quality" asset_manager-quality
  hubnet-send user-id "Price" asset_manager-price
end

;; returns string version of color name
to-report color->string [ color-value ]
  report item (position color-value colors) color-names
end

;; sends the appropriate monitor information back to one client
to send-system-info ;; owner procedure
  hubnet-send user-id "Day" day
end

;; broadcasts the appropriate monitor information back to all clients
to broadcast-system-info
  hubnet-broadcast "Day" day
end


; Copyright 2004 Uri Wilensky.
; See Info tab for full copyright and license.
