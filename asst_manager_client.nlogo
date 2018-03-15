to setup-customers
  ask customers [ die ]
  create-customers num-consumer [
    set customer-principal initial-principal
    set persuaded? false
    set my-asset-manager -1
    setxy random-xcor random-ycor
    set appeal 0
    set customer-money (inicial-principal + random 81)
    let chance random 3
    ifelse (chance = 0)[
      set color red
      set customer-risk-preference "High"
      set customer-desired-return 15 ]
    	[ ifelse (chance = 1) [ 
      		set color yellow
        	set customer-risk-preference "Medium" 
        	set customer-desired-return 10 ]
      		[ set color cyan
        		set customer-risk-preference "Low" 
						set customer-desired-return 5 ]
    	]
  	]
end

to setup-asset-managers [ number ]
  create-asset-managers number [
  set user-id who
  reset-firm-variables
  set color 32
  set size 2
  let chance (random 3)
  set asset-manager-service 5
	set company-actual-return (25 + random 50)
	set management-fee (company-actual-return + 10)
	ifelse (chance = 0) [
    set company-asset-type "High"
		set shape "circle" ]
		[ ifelse (chance = 1) [ 
      	set company-asset-type "Medium"
				set shape "triangle" ]
				[ set company-asset-type "Low"
					set shape "square" ]
    ]
    setup-location
  ]
end

to go
  ask asset-managers with [ bankrupt? = false ]
  [ serve-customers
    attract-customers ]

  ask customers ;; Move the customers
  [ move-customers ]

  if (ticks mod quarter-length) = 0 ;; slide-bar variable // Is it time to end the quarter?
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
   set customer-principal initial-principal ]

  set num-customers (num-customers + new-customers)
  set days-revenue (days-revenue + (new-customers * management-fee))
  set days-cost round (days-cost + (new-customers * variable-cost * asset-manager-service) + (new-customers * return-cost * company-actual-return))
  set days-profit round (days-revenue - days-cost)
end

to attract-customers ;; turtle procedure
  let asset-manager# user-id
  let r-x xcor
  let r-y ycor
  let r-type company-asset-type
  let adj-price (management-fee - 0.15 * asset-manager-service)
  let adj-risk (company-actual-return + 0.15 * asset-manager-service)
  let util-price false
  let util-risk false
  let asset-manager-appeal false

  ask customers with [ (customer-principal < spending-threshold) and (customer-risk-preference = r-type) ] in-radius 7
  [
    set util-price (customer-money - adj-price)
    set util-risk (adj-risk - customer-desired-return)
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
 set customer-principal customer-principal - loss-rate ;; cost of movement was originally set to 1 and now as a variable "loss-rate" which can be varied or fixed
 fd 1
end

to end-day
  set account-balance round (account-balance + days-profit)
  set days-cost fixed-cost
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

to-report High-types
  report count asset-managers with [ company-asset-type = "High" ]
end

to-report Medium-types
  report count asset-managers with [ company-asset-type = "Medium" ]
end

to-report Low-types
  report count asset-managers with [ company-asset-type = "Low" ]
end

to-report avg-profit/firm
  report mean [ days-profit ] of asset-managers
end

to-report avg-customers/firm
  report mean [ num-customers ] of asset-managers
end

to-report avg-customer-principal/customer
  report mean [ customer-principal ] of customers
end

to-report disgruntled-consumers
  report count customers with [ customer-principal < 0 ]
end

to reset-firm-variables
  set rank n/a
  set received-rank? false
  set bankrupt? false
  set account-balance 2000
  set days-revenue 0
  set days-cost fixed-cost
  set days-profit 0
  set profit-customer 100
  set num-customers 0
  set management-fee random 50
  set asset-manager-service 50 + random 50
  set company-actual-return 50 + random 50
end

;; returns string version of color name
to-report color->string [ color-value ]
  report item (position color-value colors) color-names
end
