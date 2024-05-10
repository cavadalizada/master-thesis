extensions [table]

globals [
  companyTrend
  successfulGoals
  diedAgents
  totalAgents
  EmployeeNodes
  ShopNodes
  WebNodes
  attackerModerateToHigh
  attackerLowSkill
  attackerState
  threatEvent1
  threatEvent2
  threatEvent3
  listOfPatchingNodes
  isStatic
  weekdays-normalized-2023
  normalized-2023
  newApp
  releaseScenario
]

directed-link-breed [http-connections http-connection]
directed-link-breed [https-connections https-connection]
directed-link-breed [sql-connections sql-connection]

undirected-link-breed [is-process-ofs is-process-of]
undirected-link-breed [network-connections network-connection]

turtles-own [
  isSource
  internal
  type1
  knownVulnerabilities
  potentialMisconfigs
  historicalExploitRate
  misconfigurations
  runningAs
  version
  hasAWSKeys
  skill
  isCustom
  misconfigChance
  globalCveChance
  accessLevels
  programmingTechnology
  programmingTechnologyExploitationRate
  SSRFexploitationRate
  RCEexploitationRate
  SQLIexploitationRate
  functionalityFileUpload
  functionalityConnectsToOtherApp
  functionalityConnectsToDatabase
  functionalityRunningAsHigherPriv
  BreakOutFromDesktopApp
  revealOtherAppExploitationRate
  BreakOutFromDesktopAppFunctionality
]
breed [servers server]
breed [databases database]
breed [applications application]
breed [desktop-applications desktop-application]
breed [workstations workstation]
breed [users user]
breed [s3s s3]

breed [attackers attacker]

attackers-own [
  location
  list-of-access
  prevLocation
  prevprevLocation
  stuckDetector
  prevStuckLabel
  stuckCount
  globalStuckCount
  globalglobalStuckCount
  pathTaken
  exploitedCVEs
  startLabel
  exploitedMisconfigs
  goalLabel
]

to setup

  set weekdays-normalized-2023 [0.02 0.373 0.711 0.265 0.241 0.072 0.8]
  set normalized-2023 [1.00 0.65 0.50 0.56 0.69 0.47 0.34 0.44 0.55 0.54 0.66 0.49]
  ;; create company
  set companyScore (10 + random 10)

  create-s3s 1 [
    set label "S3"
    set type1 "cloud"
    setxy 10 10
    set size 3
    set isCustom false
    set shape "cloud"

    set isSource false;
  ]

    ;; DATABASE SERVER
    create-servers 1 [
    set label "Database Server"
    set type1 "server"
    setxy 4 4
    set size 3
    set isCustom false


    set misconfigChance 100
    set globalCveChance 73

    set accessLevels table:make

    table:put accessLevels 1 "user"
    table:put accessLevels 2 "root"

    set knownVulnerabilities table:make

    set potentialMisconfigs table:make


    set shape "Server"

    set isSource false;




  ]

  ;; DATABASE
  create-databases 1 [
    set type1 "database"
    setxy 0 2
    set size 2
    set label "Database"
    set shape "db"
    set isSource false;
    set isCustom false

    set accessLevels table:make

    table:put accessLevels 1 "db_user"
    table:put accessLevels 2 "server"

    create-is-process-ofs-with servers with [label = "Database Server"] [
    set color orange
    set thickness 0.3
    ];
  ]

    ;; TOOL SERVER
    create-servers 1 [
    set type1 "server"
    setxy 4 0
    set size 3
    set isCustom false

    set accessLevels table:make

    table:put accessLevels 1 "user"
    table:put accessLevels 2 "root"

    set knownVulnerabilities table:make

    set potentialMisconfigs table:make

    set misconfigChance 100 ;;
    set globalCveChance 73 ;;

    set shape "Server"
    set label "Tool Server"
    set isSource false;


    create-network-connections-with servers with [label = "Database Server"] [
    set color green
    set thickness 0.3
    ];
  ]

   ;; BACKUP SYNCER
  create-applications 1 [
    set label "Backup Syncer"

    set misconfigChance 250

    set isCustom false

    set type1 "app"
    setxy 9 2

    set size 2
    set shape "app"

    set accessLevels table:make

    table:put accessLevels 1 "app_user"
    table:put accessLevels 2 "app_admin"
    table:put accessLevels 4 "server"
    table:put accessLevels 5 "database"


    set knownVulnerabilities table:make

    set potentialMisconfigs table:make


    set isCustom true
    set programmingTechnology "Bash"
    set SQLIexploitationRate 1 / 300000 ;; 1 in 3000 for 100 skilled
    set RCEexploitationRate 1 / 400000 ;; 1 in 4000
    set functionalityConnectsToOtherApp false
    set functionalityConnectsToDatabase true
    set functionalityFileUpload true


    set isSource false;

    create-is-process-ofs-with servers with [label = "Tool Server"] [
    set color orange
    set thickness 0.3
    ];
    create-sql-connections-to databases with [label = "Database"] [
    set thickness 0.3
    set color pink
    ];
    create-https-connection-to one-of s3s with [label = "S3"] [
      set color red
      set thickness 0.3
    ] ;

  ]


  ;; INVENTORY PROCESSOR
  create-applications 1 [
    set label "Inventory Processor"

    set accessLevels table:make

    table:put accessLevels 1 "app_user"
    table:put accessLevels 2 "app_admin"
    table:put accessLevels 4 "server"
    table:put accessLevels 5 "database"

    set misconfigChance 250

    set knownVulnerabilities table:make

    set potentialMisconfigs table:make

    set isCustom true
    set programmingTechnology "PHP"
    set SQLIexploitationRate 1 / 300000 ;; 1 in 3000 chance for there to be sqli here
    set RCEexploitationRate 1 / 400000 ;; 1 in 4000 chance for there to be rce here

    set functionalityConnectsToOtherApp false
    set functionalityConnectsToDatabase true
    set functionalityFileUpload true

    set shape "app"
    set type1 "app"
    setxy 0 -2

    set size 2

    set isSource false;

    create-is-process-ofs-with servers with [label = "Tool Server"] [
    set color orange
    set thickness 0.3
    ];
    create-sql-connections-to databases with [label = "Database"] [
    set thickness 0.3
    set color pink
    ];
  ]

  ;; WEB SERVER
    create-servers 1 [
    set label "Web Server"

    set type1 "server"
    setxy 4 -8
    set size 3

    set accessLevels table:make

    table:put accessLevels 1 "user"
    table:put accessLevels 2 "root"

    set potentialMisconfigs table:make

    set knownVulnerabilities table:make

    set misconfigChance 100
    set globalCveChance 73
    set isCustom false;
    set shape "Server"
    set isSource false;


    create-network-connections-with servers with [label = "Tool Server"] [
    set color green
    set thickness 0.3
    ];
  ]

      ;; WORKSTATION
    create-workstations 1 [
    set label "Workstation"
    set type1 "workstation"
    setxy -7 0
    set size 3

    set accessLevels table:make

    table:put accessLevels 1 "user"
    table:put accessLevels 2 "root"

    set misconfigChance 120
    set globalCveChance 61

    set potentialMisconfigs table:make

    set knownVulnerabilities table:make


    set shape "pc"
    set isCustom false;
    set isSource false;

    create-network-connections-with servers with [label = "Tool Server"] [
    set color green
    set thickness 0.3
    ];

    ]

    ;; INVENTORY DESKTOP APPLICATION
    create-desktop-applications 1 [
    set label "Inventory App"
    set type1 "desktop-app"
    setxy -7 -3
    set size 2

    set knownVulnerabilities table:make

    set potentialMisconfigs table:make

    set accessLevels table:make

    table:put accessLevels 1 "app_user"
    table:put accessLevels 2 "other_app"
    table:put accessLevels 4 "workstation"

    set isCustom true
    set programmingTechnology ".NET"
    set functionalityConnectsToOtherApp true
    set BreakOutFromDesktopAppFunctionality true
    set revealOtherAppExploitationRate 1 / 80 ;; 1 in 80 chance
    set BreakOutFromDesktopApp 1 / 60 ;; 1 in 60 chance
    set functionalityRunningAsHigherPriv false
    set misconfigChance 150 ;; 1 in 100

    set shape "app"

    set isSource false;

    create-http-connections-to applications with [label = "Inventory Processor"] [
    set color blue
    set thickness 0.3
    ];

    create-is-process-ofs-with workstations with [label = "Workstation"] [
    set color orange
    set thickness 0.3
    ];

  ]

  ;; E-STORE
    create-applications 1 [
    set label "E-store"

    set accessLevels table:make

    table:put accessLevels 1 "app_user"
    table:put accessLevels 2 "app_admin"
    table:put accessLevels 3 "other_app"
    table:put accessLevels 4 "server"

    set type1 "app"
    set shape "app"
    setxy 0 -6
    set size 2

    set knownVulnerabilities table:make

    set potentialMisconfigs table:make

    set misconfigChance 250

    set isCustom true
    set programmingTechnology "PHP"

    set RCEexploitationRate 1 / 500000 * release-rate-of-today ;; 1 in 5000 chance for rce
    set SSRFexploitationRate 1 / 400000 * release-rate-of-today;; 1 in 4000 cance for ssrf
    set functionalityFileUpload true
    set functionalityConnectsToOtherApp true
    set functionalityConnectsToDatabase false

    set isSource false;

    create-http-connections-to applications with [label = "Inventory Processor"] [
    set color blue
    set thickness 0.3
    ];
    create-is-process-ofs-with servers with [label = "Web Server"] [
    set color orange
    set thickness 0.3
    ];
  ]

    ;; Company website
   create-applications 1 [
    set label "Company Website"

    set accessLevels table:make

    table:put accessLevels 1 "app_user"
    table:put accessLevels 2 "app_admin"
    table:put accessLevels 4 "server"

    set type1 "app"
    set shape "app"
    setxy 8 -10
    set size 2

    set globalCveChance 146 ;; 1 in 146 chance for global cve
    set misconfigChance 730 ;; 1 in 730 chance for global misconfig

    set potentialMisconfigs table:make

    set knownVulnerabilities table:make



    set isCustom false


    set isSource false;

    create-is-process-ofs-with servers with [label = "Web Server"] [
    set color orange
    set thickness 0.3
    ];
  ]


  ;; NGINX PROXY
    create-applications 1 [
    set label "Nginx Proxy"
    set type1 "app"
    setxy 0 -10
    set size 2

    set accessLevels table:make

    table:put accessLevels 1 "other_app"
    table:put accessLevels 2 "server"

    set globalCveChance 1217  ;; 1 in 22 831 chance for a global cve to be found
    set misconfigChance 912 ;; 1 in 1000 chance for a misconfig to happen here

    set isCustom false


    set potentialMisconfigs table:make


    set knownVulnerabilities table:make



    set shape "app"
    set isSource false;

    create-is-process-ofs-with servers with [label = "Web Server"] [
    set color orange
    set thickness 0.3
    ];
    create-http-connections-to applications with [label = "E-store"] [
    set color blue
    set thickness 0.3
    ];
  ]

  create-users 1 [
   setxy 0 -14
   set size 2
   set type1 "user"
   set shape "circle"
   set label "Shop User"
   set isSource true ;
    create-https-connection-to one-of applications with [label = "Nginx Proxy"] [
      set color red
      set thickness 0.3
    ] ;
  ]
  create-users 1 [
   setxy -12 -3
   set size 2
   set type1 "user"
   set shape "circle"
   set label "Employee User"
   set isSource true ;
   set internal true ;
    create-https-connection-to one-of desktop-applications with [label = "Inventory App"] [
      set color red
      set thickness 0.3
    ] ;
  ]
 create-users 1 [
   setxy 8 -14
   set size 2
   set type1 "user"
   set shape "circle"
   set label "Web User"
   set isSource true ;
    create-https-connection-to one-of applications with [label = "Company Website"] [
      set color red
      set thickness 0.3
    ] ;
  ]
end

to-report filter-rows-by-criteria [input-table currentPrivilege skillLevel privilegeResulted]
  let result table:make  ; Create a new table for the result
  ; Determine the category of skillLevel based on its value
  ifelse skillLevel > 80 [
    set skillLevel "High"
  ] [
    ifelse skillLevel > 50 [
      set skillLevel "Medium"
    ] [
      set skillLevel "Low"
    ]
  ]
  ; Iterate over each key-value pair in the input table
  foreach (table:keys input-table) [
    [key] ->
    let value table:get input-table key

    ; Check if the row meets the criteria based on skillLevel and impactLevel
    let skillReq table:get value "SkillRequired"
    let privRes table:get value "PrivilegeResulted"
    let privReq table:get value "PrivilegeRequired"
    let exist table:get value "Exists"
    ifelse (privReq <= currentPrivilege and exist = true) [
      ifelse (privRes = privilegeResulted) [
        ifelse (skillLevel = "High") [
          if member? skillReq ["High" "Medium" "Low"] [
            table:put result key value  ; Add the row to the result table if it meets the criteria
          ]
        ] [
          ifelse (skillLevel = "Medium") [
            if member? skillReq ["Medium" "Low"] [
              table:put result key value  ; Add the row to the result table if it meets the criteria
            ]
          ] [
            if (skillReq = "Low") [
              table:put result key value  ; Add the row to the result table if it meets the criteria
            ]
          ]
        ]
       ] []
      ] []
  ]

  report result  ; Return the filtered table
end

to-report find-rows-with-skill [input-table skillLevel]
  let result table:make
  foreach (table:keys input-table) [
    [key] ->
    let nested-table table:get input-table key
      let skill-required table:get-or-default nested-table "SkillRequired" ""
      if skill-required = skillLevel [  ; Assuming "" represents 'None'
        table:put result key nested-table
      ]
  ]
  report result
end

to-report is-table-empty [input-table]
  ; Check if the length of the table is 0
  report table:length input-table = 0
end

to addToExploitedCVEs [attackerName nodeLabel CVElabel]
  ask attackers with [label = attackerName] [
    ; Check if nodeLabel already exists in the exploitedCVEs table
    if not table:has-key? exploitedCVEs nodeLabel [
      ; If not, create a new table for this nodeLabel
      table:put exploitedCVEs nodeLabel table:make
    ]

    ; Get the CVE table for this node
    let nodeCVEs table:get exploitedCVEs nodeLabel

    ; Add or update the CVElabel in this table with value true
    table:put nodeCVEs CVElabel true
  ]
end

to-report has-exploited-cve [attackerName CVElabel]
  ; Find the attacker with the given name
  let target-attacker one-of attackers with [label = attackerName]
  let nodeLabel [label] of one-of turtles-here with [type1 != "attacker"]

  ; Check if the attacker exists
  if target-attacker = nobody [
    report false
  ]

  ; Retrieve the exploitedCVEs table of the target attacker
  let attacker-cves [exploitedCVEs] of target-attacker

  ; Check if the nodeLabel exists and has the key Mslabel
  if table:has-key? attacker-cves nodeLabel [
    let nodeCves table:get attacker-cves nodeLabel
    if table:has-key? nodeCves CVElabel [
      report true
    ]
  ]

  report false
end

;; add to exploited misconfigs of node
to addToExploitedMisconfigs [attackerName nodeLabel Mslabel]
  ask attackers with [label = attackerName] [
    ; Check if nodeLabel already exists in the exploitedMisconfigs table
    if not table:has-key? exploitedMisconfigs nodeLabel [
      ; If not, create a new table for this nodeLabel
      table:put exploitedMisconfigs nodeLabel table:make
    ]

    ; Get the Misconfig table for this node
    let nodeMis table:get exploitedMisconfigs nodeLabel

    ; Add or update the Misconfig label in this table with value true
    table:put nodeMis Mslabel true
  ]
end

;;
to-report has-exploited-misconfig [attackerName Mslabel]
  ; Find the attacker with the given name
  let target-attacker one-of attackers with [label = attackerName]
  let nodeLabel [label] of one-of turtles-here with [type1 != "attacker"]

  ; Check if the attacker exists
  if target-attacker = nobody [
    report false
  ]

  ; Retrieve the exploitedCVEs table of the target attacker
  let attacker-misconfigs [exploitedMisconfigs] of target-attacker

  ; Check if the nodeLabel exists and has the key Mslabel
  if table:has-key? attacker-misconfigs nodeLabel [
    let nodeMisconfigs table:get attacker-misconfigs nodeLabel
    if table:has-key? nodeMisconfigs Mslabel [
      report true
    ]
  ]

  report false
end


to exploitMisconfigs [copyOfMisConfigurations copyOfcurrentPrivilege copyOfskillLevel copyOfattackerName]
     ;; Check misconfigs
   let filteredTable filter-rows-by-criteria copyOfMisConfigurations copyOfcurrentPrivilege copyOfskillLevel 2
  if not is-table-empty filteredTable and not has-exploited-misconfig copyOfattackerName first table:keys filteredTable  [
     ;;show ( word copyOfattackerName " on " label " exploited " first table:keys filteredTable  )
     let misconfig table:get copyOfMisConfigurations first table:keys filteredTable
     table:put misconfig "TickCreated" ticks
     table:put copyOfMisConfigurations first table:keys filteredTable misconfig
     addToExploitedMisconfigs copyOfattackerName label first table:keys filteredTable
     setCurrentPrivilege copyOfattackerName label 2
     ]
   set filteredTable filter-rows-by-criteria copyOfMisConfigurations copyOfcurrentPrivilege copyOfskillLevel 3
  if not is-table-empty filteredTable and not has-exploited-misconfig copyOfattackerName first table:keys filteredTable  [
     ;;show ( word copyOfattackerName " on " label " exploited " first table:keys filteredTable  )
     let misconfig table:get copyOfMisConfigurations first table:keys filteredTable
     table:put misconfig "TickCreated" ticks
     table:put copyOfMisConfigurations first table:keys filteredTable misconfig
     addToExploitedMisconfigs copyOfattackerName label first table:keys filteredTable
     setCurrentPrivilege copyOfattackerName label 3
     ]
   set filteredTable filter-rows-by-criteria copyOfMisConfigurations copyOfcurrentPrivilege copyOfskillLevel 4
  if not is-table-empty filteredTable and not has-exploited-misconfig copyOfattackerName first table:keys filteredTable  [
     let misconfig table:get copyOfMisConfigurations first table:keys filteredTable
     table:put misconfig "TickCreated" ticks
     table:put copyOfMisConfigurations first table:keys filteredTable misconfig
     ;;show ( word copyOfattackerName " on " label " exploited " first table:keys filteredTable  )
     addToExploitedMisconfigs copyOfattackerName label first table:keys filteredTable
     setCurrentPrivilege copyOfattackerName label 4
     ]
end

to exploitCVEs [copyOfknownVulnerabilities copyOfcurrentPrivilege copyOfskillLevel copyOfattackerName]
     ;; Check known vulnerabilities
   let filteredTable filter-rows-by-criteria copyOfknownVulnerabilities copyOfcurrentPrivilege copyOfskillLevel 2
   if not is-table-empty filteredTable and not has-exploited-cve copyOfattackerName first table:keys filteredTable  [
     ;;show ( word copyOfattackerName " on " label " exploited " first table:keys filteredTable  )
     addToExploitedCVEs copyOfattackerName label first table:keys filteredTable
     setCurrentPrivilege copyOfattackerName label 2
     ]
   set filteredTable filter-rows-by-criteria copyOfknownVulnerabilities copyOfcurrentPrivilege copyOfskillLevel 3
   if not is-table-empty filteredTable and not has-exploited-cve copyOfattackerName first table:keys filteredTable  [
     ;;show ( word copyOfattackerName " on " label " exploited " first table:keys filteredTable  )
     addToExploitedCVEs copyOfattackerName label first table:keys filteredTable
     setCurrentPrivilege copyOfattackerName label 3
     ]
   set filteredTable filter-rows-by-criteria copyOfknownVulnerabilities copyOfcurrentPrivilege copyOfskillLevel 4
   if not is-table-empty filteredTable and not has-exploited-cve copyOfattackerName first table:keys filteredTable  [
     ;;show ( word copyOfattackerName " on " label " exploited " first table:keys filteredTable  )
     addToExploitedCVEs copyOfattackerName label first table:keys filteredTable
     setCurrentPrivilege copyOfattackerName label 4
     ]
end

to create-and-add-cve-to-node [nodeLabel skillLevel privilegeRequired privilegeResulted]
  ask turtles with [label = nodeLabel][

      ifelse skillLevel > 80 [
        set skillLevel "High"
    ] [
      ifelse skillLevel > 50 [
        set skillLevel "Medium"
      ] [
        set skillLevel "Low"
      ]
    ]

    let customCve table:make

    table:put customCve "SkillRequired" skillLevel
    table:put customCve "PrivilegeRequired" privilegeRequired
    table:put customCve "PrivilegeResulted" privilegeResulted
    table:put customCve "Exists" true
    table:put customCve "TickCreated" ticks
    table:put knownVulnerabilities (word "customCve-" ticks "-" random 5) customCve

    set customCve 0
  ]
end

to create-and-add-misconfig-to-node [nodeLabel skillLevel privilegeRequired privilegeResulted]
  ask turtles with [label = nodeLabel][

      ifelse skillLevel > 80 [
        set skillLevel "High"
    ] [
      ifelse skillLevel > 50 [
        set skillLevel "Medium"
      ] [
        set skillLevel "Low"
      ]
    ]

    let customMs table:make

    table:put customMs "SkillRequired" skillLevel
    table:put customMs "PrivilegeRequired" privilegeRequired
    table:put customMs "PrivilegeResulted" privilegeResulted
    table:put customMs "Exists" true
    table:put customMs "MisConfigCreated" ticks

    table:put potentialMisconfigs (word "customMs-" ticks "-" random 100 who) customMs

    set customMs 0
  ]
end

to expire-vulnerabilities-and-misconfigs [CopyOfknownVulnerabilities CopyOfpotentialMisconfigs]

  let keys table:keys CopyOfknownVulnerabilities

      ; Iterate through each key to find custom CVEs
      foreach keys [
        [key] ->
        ; Check if the key starts with "customCve-"
        if substring key 0 6 = "custom" [
          ; Retrieve the vulnerability details
          let vulnerability table:get CopyOfknownVulnerabilities key
          let tickCreated table:get vulnerability "TickCreated"

          ; Check if the current tick count is more than 3 ticks since the CVE was created
          if (ticks - tickCreated) > 3 [
            ; Update the 'Exists' field to false
            ;;show (word "Fixing " key)
            table:put vulnerability "Exists" false
            table:put CopyOfknownVulnerabilities key vulnerability
          ]
        ]
      ]

    set keys table:keys CopyOfpotentialMisconfigs

      ; Iterate through each key to find custom CVEs
      foreach keys [
        [key] ->
        ; Check if the key starts with "custom"
        if substring key 0 6 = "custom" [
          ; Retrieve the vulnerability details
          let misconfig table:get CopyOfpotentialMisconfigs key

          ;; check if tickcreated exists
          ifelse table:has-key? misconfig "TickCreated" [

          let tickCreated table:get misconfig "TickCreated"
          ; Check if the current tick count is more than 3 ticks since the CVE was created
          if (ticks - tickCreated) > 3 [
            ; Update the 'Exists' field to false
            ;;show (word "Fixing " key)
            table:put misconfig "Exists" false
            table:put CopyOfpotentialMisconfigs key misconfig
          ]
      ][if table:has-key? misconfig "MisConfigCreated" [
         let misconfigCreated table:get misconfig "MisConfigCreated"
          if (ticks - misconfigCreated) > 30 [
          ifelse random 2 = 1 [
            ; Update the 'Exists' field to false
            ;;show (word "Fixing " key)
            table:put misconfig "Exists" false
            table:put CopyOfpotentialMisconfigs key misconfig
          ][
            table:put misconfig "MisConfigCreated" ticks + 10 ;; give 20 more days
            ]
          ]
      ]]
    ]
      ]

end

to-report month-from-tick
  ; Assuming the simulation starts in January and each month has 30 days
  report (ticks / 30) mod 12 + 1
end

to-report switch [day]
  ; Define a list where each index corresponds to the day minus one and the value at each index is the rate
  let rates [1 1.3 1.2 1.2 1.2 1.1 1.1 1.1 1.1 1.05 1.03 1 0.98 0.95 0.9 0.85 0.8 0.75]
  
  ; Check if the day is within the range of the list length
  if day > 0 and day <= length rates [
    report item (day - 1) rates
  ]
  
  ; Default rate if day is out of bounds
  report 1
end

to-report release-rate-of-today
   if isStatic [
    report 1
  ]
  if releaseScenario != True [
    report 1
  ]
  let current-month month-from-tick
  let current-day ticks + 1  ; since ticks start at 0, add 1 to represent the day of the month correctly

  if newApp [
    report 0.7
  ]

  ifelse current-month = 6 [
    report switch current-day
  ] [
    if current-month = 7 [
      if current-day = 18 [
        set newApp true
        report 0.72
      ]
      report switch current-day
    ] 
  ]
  report 1
end

to-report get_daily_rate
  ifelse isStatic [
    report 1
  ] [
    let current-month month-from-tick
    let current-day ticks
    let weekday (current-day mod 7)  ; Calculate weekday (0-6) assuming ticks start on a Sunday
    
    let month-index current-month - 1  ; Month index for the normalized-2023 list
    let month-rate item month-index normalized-2023
    
    let weekday-rate item weekday weekdays-normalized-2023
    
    report (month-rate + 1) * (weekday-rate + 1)  ; Calculate the rate for today 
  ]
end


to introduce-misconfigs
  ;;show misconfigChance
  if random misconfigChance / get_daily_rate = 0 [
     let keys table:keys accessLevels
     let midpoint length keys / 2

    let lower_numbers sublist keys 0 midpoint
    let upper_numbers sublist keys midpoint length keys

    let random_lower one-of lower_numbers
    let random_upper one-of upper_numbers
    ;;show (word "Introducing Misconfig for " label)
    create-and-add-misconfig-to-node label (40 + random 61) random_lower random_upper

  ]


end

to introduce-cves

  if random globalCveChance / get_daily_rate = 0 and isCustom != true [
     let keys table:keys accessLevels
     let midpoint length keys / 2

    let lower_numbers sublist keys 0 midpoint
    let upper_numbers sublist keys midpoint length keys

    let random_lower one-of lower_numbers
    let random_upper one-of upper_numbers
    ;;show (word "Introducing CVE for " label)
    create-and-add-cve-to-node label (40 + random 61) random_lower random_upper

  ]


end

to update-vulnerabilities
  ask turtles with [type1 != "attacker" and type1 != "database" and type1 != "cloud" and isSource != true] [
      ; Expire old issues
      expire-vulnerabilities-and-misconfigs knownVulnerabilities potentialMisconfigs

      ;; Introduce misconfigs
      introduce-misconfigs
      ;; introduce cves found in other places
      introduce-cves
  ]
end

to patch-vulnerabilities-and-misconfigs
  ; Iterate through each turtle listed for patching
  ask listOfPatchingNodes [
    ; Assume 'knownVulnerabilities' and 'potentialMisconfigs' are agent variables

    ; Calculate how many vulnerabilities and misconfigs to patch, rounding down
    let numToPatchVulnerabilities floor (0.6 * table:length knownVulnerabilities)
    let numToPatchMisconfigs floor (0.6 * table:length potentialMisconfigs)

    ; Patch vulnerabilities if available
    if numToPatchVulnerabilities > 0 [
      let patchedVulnerabilities 0
      foreach table:keys knownVulnerabilities [
        [key] ->
        if patchedVulnerabilities < numToPatchVulnerabilities [
          let vulnerability table:get knownVulnerabilities key
          table:put vulnerability "Exists" false
          table:put knownVulnerabilities key vulnerability
          set patchedVulnerabilities patchedVulnerabilities + 1
        ]
      ]
    ]

    ; Patch misconfigs if vulnerabilities are fully patched or not available
    if (numToPatchVulnerabilities = 0 or table:length knownVulnerabilities <= numToPatchVulnerabilities) and numToPatchMisconfigs > 0 [
      let patchedMisconfigs 0
      foreach table:keys potentialMisconfigs [
        [key] ->
        if patchedMisconfigs < numToPatchMisconfigs [
          let misconfig table:get potentialMisconfigs key
          table:put misconfig "Exists" false
          table:put potentialMisconfigs key misconfig
          set patchedMisconfigs patchedMisconfigs + 1
        ]
      ]
    ]

    ; Update the turtle's own data with the patched tables
    ; No need for table:put as agent variables knownVulnerabilities and potentialMisconfigs
    ; are directly modified within the turtle's scope
  ]
end

; Function to add a turtle to the listOfPatchingNodes by its label
to add-to-patching-list [turtleLabel]
  ; Find the turtle with the given label and add it to the list
  let targetTurtle one-of turtles with [label = turtleLabel]
  if targetTurtle != nobody [
    set listOfPatchingNodes lput targetTurtle listOfPatchingNodes
  ]
end

to exploit [skillLevel currentPrivilege attackerName]
   (ifelse
    type1 = "server" [
      set label-color red
      ;; Check known vulnerabilities
      exploitMisconfigs potentialMisconfigs currentPrivilege skillLevel attackerName
      exploitCVEs  knownVulnerabilities currentPrivilege skillLevel attackerName

      finishExploit attackerName

    ]
    type1 = "desktop-app" [
      (ifelse
       isCustom = true [

        ;; Check misconfigs
        exploitMisconfigs potentialMisconfigs currentPrivilege skillLevel attackerName
        ;; Check known vulnerabilities
        exploitCVEs knownVulnerabilities currentPrivilege skillLevel attackerName

        ;; app is custom has a random chance to be
        let exploitChance 0
        ;; Check if the attacker sees a connection to another app and tries to exploit it
        (if functionalityConnectsToOtherApp [
          set exploitChance (revealOtherAppExploitationRate * skillLevel) * 100000 ;; independent events
          ;;show "RevealOtherApp"
          ;;show skillLevel
          ;;show exploitChance
          if random 100000 < exploitChance [
            if skillLevel < 81 [ ;; if attacker is not very skilled, they share the vulnerability with the world
              create-and-add-cve-to-node label random skillLevel currentPrivilege 2
            ]
            ;;show ( word attackerName " on " label " exploited a custom PrivEsc vulnerability" )
            setCurrentPrivilege attackerName label 2  ; set priv to workstation
          ]
        ])

        ;; Check if the attacker sees an opportunity to break out from a desktop application
        (if BreakOutFromDesktopAppFunctionality [
          set exploitChance (BreakOutFromDesktopApp * skillLevel) * 100000 ;; independent events
         ;;show exploitChance
          if random 100000 < exploitChance [
            if skillLevel < 81 [ ;; if attacker is not very skilled, they share the vulnerability with the world
              create-and-add-cve-to-node label random skillLevel currentPrivilege 4
            ]
            ;;show ( word attackerName " on " label " exploited a custom PrivEsc vulnerability" )
            setCurrentPrivilege attackerName label 4  ; set priv to workstation
          ]
        ])

         finishExploit attackerName
        ]
        isCustom = false[
        ;; Check misconfigs
        exploitMisconfigs potentialMisconfigs currentPrivilege skillLevel attackerName
        ;; Check known vulnerabilities
        exploitCVEs knownVulnerabilities currentPrivilege skillLevel attackerName

        finishExploit attackerName
      ])


    ]
    type1 = "app" [
       set label-color red

      (ifelse
       isCustom = true [

        ;; Check misconfigs
        exploitMisconfigs potentialMisconfigs currentPrivilege skillLevel attackerName
        ;; Check known vulnerabilities
        exploitCVEs knownVulnerabilities currentPrivilege skillLevel attackerName

        ;; consider attackers second run
        ;; app is custom has a random chance to be
        let exploitChance 0
        ;; attacker sees connection to other server and tries to exploit it
        (if functionalityConnectsToOtherApp [
          set exploitChance SSRFexploitationRate * skillLevel * 100000 ;; independent events
          ;;show "SSRF"
          ;;show skillLevel
          ;;show exploitChance
          if random 100000 < exploitChance [
            if skillLevel < 81 [ ;; if attacker is not very skilled they share the vulnerability with the world
              create-and-add-cve-to-node label random skillLevel currentPrivilege 3
            ]
            ;;show ( word attackerName " on " label " exploited a custom SSRF vulnerability"  )
            setCurrentPrivilege attackerName label 3
          ]
        ])

        ;; attacker sees file upload functionality and tries to exploit it
        (if functionalityFileUpload [
          set exploitChance ( RCEexploitationRate * skillLevel ) * 100000 ;; independent events
          ;;show "RCE"
          ;;show skillLevel
          ;;show exploitChance
          if random 100000 < exploitChance [
            ;;show exploitChance
            ;;show RCEexploitationRate
            ;;show label
            if skillLevel < 81 [ ;; if attacker is not very skilled they share the vulnerability with the world
              create-and-add-cve-to-node label random skillLevel currentPrivilege 4
            ]
            ;;show ( word attackerName " on " label " exploited a custom FileUpload vulnerability"  )
            setCurrentPrivilege attackerName label 4
          ]
        ])

        ;; attacker sees database connection and tries to exploit it
        (if functionalityConnectsToDatabase [
          set exploitChance ( SQLIexploitationRate * skillLevel ) * 100000;; independent events
          if random 100000 < exploitChance [
            ;;show exploitChance
            ;;show SQLIexploitationRate
            ;;show label
            if skillLevel < 81 [ ;; if attacker is not very skilled they share the vulnerability with the world
              create-and-add-cve-to-node label random skillLevel currentPrivilege 5
            ]
            ;;show ( word attackerName " on " label " exploited a custom Database Connection vulnerability"  )
            setCurrentPrivilege attackerName label 5
          ]
        ])
         finishExploit attackerName
        ]
        isCustom = false [
        ;; Check misconfigs
        exploitMisconfigs potentialMisconfigs currentPrivilege skillLevel attackerName
        ;; Check known vulnerabilities
        exploitCVEs knownVulnerabilities currentPrivilege skillLevel attackerName

        finishExploit attackerName
      ])
    ]
    type1 = "workstation" [
       set label-color red
       ;;show "exploiting workstation"
        ;; Check misconfigs
        exploitMisconfigs potentialMisconfigs currentPrivilege skillLevel attackerName
        ;; Check known vulnerabilities
        exploitCVEs knownVulnerabilities currentPrivilege skillLevel attackerName

        finishExploit attackerName

        set label-color white


    ]
    type1 = "database" [
       set label-color red


       set label-color white
    ]
    type1 = "cloud" [
       set label-color red

       set label-color white



    ]
    ; elsecommands
    [
      ;;show "exploit failed"
  ])
end

;; HELPER
;; puts key value into childtable
to put-in-child-table [parentTable childTableName newKey newValue]
  ; Check if the child table exists
  if not table:has-key? parentTable childTableName [
    ;;show (word "No child table named " childTableName " found in the parent table.")
    stop
  ]

  ; Retrieve the child table
  let childTable table:get parentTable childTableName

  ; Put the new key-value pair into the child table
  table:put childTable newKey newValue

  ; Update the child table in the parent table (optional, depending on your implementation)
  table:put parentTable childTableName childTable
end


;; HELPER
;; Checks if a given key is in the child table of a table
to-report key-not-in-child-table? [parentTable childTableKey keyToCheck]
  ; First, check if the parent table has the child table
  if not table:has-key? parentTable childTableKey [
    report true  ; If the parent doesn't have the child table, then the key doesn't exist
  ]

  ; Get the child table from the parent table
  let childTable table:get parentTable childTableKey

  ; Check if the key does not exist in the child table
  report not table:has-key? childTable keyToCheck
end

;; HELPER
;; returns highest privilege currently obtained on node
to-report highest-priv-on-node [parentTable childTableName]
  ; Check if the child table exists in the parent table
  if not table:has-key? parentTable childTableName [
    report "Child table does not exist"
  ]
  ; Get the child table
  let childTable table:get parentTable childTableName

  ; Initialize a variable to store the highest key value
  let highestKey -1  ; Assuming all keys are non-negative; adjust accordingly

  ; Iterate over the keys of the child table
  foreach (table:keys childTable) [
    [key] ->
    if is-number? key and key > highestKey [
      set highestKey key
    ]
  ]

  report highestKey
end

;; HELPER
;; returns score of child table
to-report get-child-table-score [parentTable childTableName]
  ; Check if the child table exists in the parent table
  if not table:has-key? parentTable childTableName [
    report 0
  ]

  ; Get the child table
  let childTable table:get parentTable childTableName

  ; Check if the "Score" key exists in the child table
  if table:has-key? childTable "Score" [
    report table:get childTable "Score"
  ]

  report 0
end

;; HELPER
;; increments the score of a child table by 1
to increment-child-table-score [parentTable childTableName]

  ; Get the child table
  let childTable table:get parentTable childTableName

  ; Get the current score and increment it by 1
  let currentScore table:get-or-default childTable "Score" 0
  table:put childTable "Score" (currentScore + 1)
end



to setCurrentPrivilege [attackerName nodeLabel newPrivilege]
  ask one-of attackers with [ label = attackerName ] [
    ;; if node is not in list create new table for Label with score zero
    if not table:has-key? list-of-access nodeLabel [
        let nodeLabelTable table:make
        table:put nodeLabelTable "Score" 1
        table:put nodeLabelTable newPrivilege true
        table:put list-of-access nodeLabel nodeLabelTable
    ]
    if (table:has-key? list-of-access nodeLabel and key-not-in-child-table? list-of-access nodeLabel newPrivilege ) [
        ;; if node is in list but access not in list add privilege to existing label table
        put-in-child-table list-of-access nodeLabel newPrivilege true
    ]
    if (table:has-key? list-of-access nodeLabel and key-not-in-child-table? list-of-access nodeLabel newPrivilege) [
        ;; if node and access in list, do nothing SHOULDN'T HAPPEN
       ;;show "This shouldn't happen in setCurrentPrivilesge"
      ]
    ]
end

;; HELPER
;; get key of given value
to-report get-key-for-value [input-table value]
  ; Iterate over each key in the table
  foreach (table:keys input-table) [
    [key] ->
    ; Check if the value associated with the key matches the given value
    if value = table:get input-table key [
      ; If a match is found, return the key
      report key
    ]
  ]
  ; If no match is found, return a default value or handle the case appropriately
  report "No match found"
end


;; HELPER
;; Checks if a specific permission exists for the current node in list-of-access
to-report has-permission? [attackerName nodeLabel permission]
  ;;show nodeLabel
  ;;show permission
  ;; Access list-of-access of the attacker
  let attackerAccesses [list-of-access] of one-of attackers with [label = attackerName]
  ;;show attackerAccesses
  ;; Check if the nodeLabel is in the attacker's list-of-access
  if not table:has-key? attackerAccesses nodeLabel [
    report false  ; If the nodeLabel is not in the list, the attacker doesn't have the specified permission
  ]


  ;; Get the permissions table for this node
  let permissionsTable table:get attackerAccesses nodeLabel

  ;; Check if the specified permission exists in the permissions table
  report table:has-key? permissionsTable get-key-for-value [accessLevels] of one-of turtles with [label = nodeLabel] permission
end


;; sets accesses based on exploit results
to finishExploit [attackerName]
   set label-color white
   let nodeLabel label
   let copyAccessLevels accessLevels
   let currentLocation one-of turtles-here
   let victimNeighbors link-neighbors
  ;;show (word "Finished exploiting on : " nodeLabel)
  ask one-of attackers with [ label = attackerName ] [
   let currentPriv table:get copyAccessLevels highest-priv-on-node list-of-access nodeLabel
  ;;show (word "Resulted privilege on " nodeLabel " is " currentPriv)
   let copyList-of-access list-of-access
   (ifelse
       currentPriv = "user" [
       ;;show (word "Exploit finished got access " currentPriv)
      ]currentPriv = "root" [
        ;;show (word "Exploit finished got access " currentPriv)
      ]currentPriv = "other_app" [
        ;;show (word "Exploit finished got access " currentPriv)
      ]currentPriv = "server" [
        ;;show (word "Exploit finished got access " currentPriv)
      ]currentPriv = "database" [
        ;;show (word "Exploit finished got access " currentPriv)
      ]currentPriv = "app_user" [
        ;;show (word "Exploit finished got access " currentPriv)
      ]
  )
  ]
end

to-report getLowestLevel [input-table]
  ; Check if the table is empty
  ifelse table:length input-table > 0 [
    ; Get the first key
    let firstKey first table:keys input-table
    ; Return the first key-value pair as a list
    report firstKey
  ] [
    ; Return -1 if the table is empty
    report -1
  ]
end

to-report is-agentset-empty [agentset]
  report not any? agentset
end


;; HELPER
;; return database with score 0 or nonexistent
to-report database-neighbor-with-score [inputScore]
      ;; Try moving to database with score 0 or doesn't exist
      if not is-agentset-empty [link-neighbors with [type1 = "database"]] of location [
        ; Get the agentset of database neighbors
        let database-neighbors [link-neighbors with [type1 = "database"]] of location

        ; Iterate over each database neighbor and check its score
        foreach sort database-neighbors [
        [db-neighbor] ->
          if get-child-table-score list-of-access [label] of db-neighbor = inputScore [
            ; Report the specific agent whose score is 0
            report db-neighbor
          ]
        ]
      ]
      report 0
end

;; HELPER
;; return server with score 0 or nonexistent
to-report server-neighbor-with-score [inputScore]
      ;; Try moving to server with score 0 or doesn't exist
      if not is-agentset-empty [link-neighbors with [type1 = "server"]] of location [
        ; Get the agentset of server neighbors
        let server-neighbors [link-neighbors with [type1 = "server"]] of location

        ; Iterate over each server neighbor and check its score
        foreach sort server-neighbors [
         [sv-neighbor] ->
          if get-child-table-score list-of-access [label] of sv-neighbor = inputScore [
            ; Report the specific agent whose score is 0
            report sv-neighbor
          ]
        ]
      ]
     report 0
end

;; HELPER
;; return app with score 0 or nonexistent
to-report app-neighbor-with-score [inputScore]
      ;; Try moving to app with score 0 or doesn't exist
      if not is-agentset-empty [link-neighbors with [ type1 = "app"]] of location [
        ; Get the agentset of app neighbors
        let app-neighbors [link-neighbors with [ type1 = "app"]] of location

        ; Iterate over each app neighbor and check its score
        foreach sort app-neighbors [
         [ap-neighbor] ->
          if get-child-table-score list-of-access [label] of ap-neighbor = inputScore [
            ; Report the specific agent whose score is 0
            report ap-neighbor
          ]
        ]
      ]
     report 0
end

;; HELPER
;; return app with score 0 or nonexistent
to-report desktop-app-neighbor-with-score [inputScore]
      ;; Try moving to app with score 0 or doesn't exist
      if not is-agentset-empty [link-neighbors with [ type1 = "desktop-app"]] of location [
        ; Get the agentset of app neighbors
        let desktop-app-neighbors [link-neighbors with [ type1 = "desktop-app"]] of location

        ; Iterate over each app neighbor and check its score
        foreach sort desktop-app-neighbors [
         [Dap-neighbor] ->
          if get-child-table-score list-of-access [label] of Dap-neighbor = inputScore [
            ; Report the specific agent whose score is 0
            report Dap-neighbor
          ]
        ]
      ]
     report 0
end

;; HELPER
;; return app with score 0 or nonexistent
to-report workstation-neighbor-with-score [inputScore]
      ;; Try moving to app with score 0 or doesn't exist
      if not is-agentset-empty [link-neighbors with [ type1 = "workstation"]] of location [
        ; Get the agentset of app neighbors
        let workstation-neighbors [link-neighbors with [ type1 = "workstation"]] of location

        ; Iterate over each app neighbor and check its score
        foreach sort workstation-neighbors [
         [wk-neighbor] ->
          if get-child-table-score list-of-access [label] of wk-neighbor = inputScore [
            ; Report the specific agent whose score is 0
            report wk-neighbor
          ]
        ]
      ]
     report 0
end


;; HELPER
;; return app with score 0 or nonexistent
to-report app-neighbor-with-score-exclude-agentset [currentApp inputScore excludedAgentset]
  ;; Check for app neighbors, excluding those in excludedAgentset
  let app-neighbors [link-neighbors with [ type1 = "app" and not member? self excludedAgentset ]] of currentApp
  ;; Proceed only if there are any eligible app neighbors
  if not is-agentset-empty app-neighbors [
    ; Iterate over each app neighbor and check its score
    foreach sort app-neighbors [
      [ap-neighbor] ->
      if get-child-table-score list-of-access [label] of ap-neighbor = inputScore [
        ; Report the specific agent whose score matches inputScore
        report ap-neighbor
      ]
    ]
  ]

  report 0
end

;; HELPER
to-report check-if-priv-for-node [copy-of-list-of-access nodeLabel priv]
  ; Check if the child table exists in the parent table
  if table:has-key? copy-of-list-of-access nodeLabel [
    ; Get the child table
    let childTable table:get copy-of-list-of-access nodeLabel

    ; Check if the child table has the key 'priv' and its value is true
    if table:has-key? childTable priv [

      report (table:get childTable priv = true)
    ]
  ]
  report false
end

;; HELPER

to-report neighbor-app-of-connected-app-with-score [score serverNeighborApps]
     if not is-agentset-empty [link-neighbors with [ type1 = "app"]] of location [
     ; Get the agentset of app neighbors
     let app-neighbors [link-neighbors with [ type1 = "app"]] of location

     ; Iterate over each app neighbor and check its score
     foreach sort app-neighbors [
      [ap-neighbor] ->
      let resultApp app-neighbor-with-score-exclude-agentset ap-neighbor score serverNeighborApps
      if resultApp != 0 [
       report resultApp
      ]
       ]
     ]
  report 0


end

;; move legally
;; WITHOUT EXPLOIT from server, workstation or source we can move to app ;; but we can NOT move to server from app
;; WIHTOUT exploit we can move from server to database ONLY IF we have root
;; IF CAN'T MOVE just exploit attempt again.
;; IF STUCK MORE THAN twice go back
;; IF STUCK AGAIN give up
to-report move-legal [attackerName]


  let currentNode turtles-here with [ type1 != "attacker"]
  let copyList-of-access list-of-access


  ;;show (word "Currently on " [label] of currentNode )
  let nextTarget 0
  ;; this is the table of legal moves in order of importance
  (ifelse
    ;; IF CURRENTLY ON SOURCE
    ([isSource] of currentNode = [true])[
    ;;show "Current node type is isSource"
    let score 0
    while [score <= 3] [
      ; Check database neighbor with the current score
      set nextTarget database-neighbor-with-score score
      if nextTarget != 0 [
        ;;show (word "Moving to database with score " score)
        report nextTarget
      ]

      ; Check server neighbor with the current score
      set nextTarget server-neighbor-with-score score
      if nextTarget != 0 [
        ;;show (word "Moving to server with score " score)
        report nextTarget
      ]

      ; Check app neighbor with the current score
      set nextTarget app-neighbor-with-score score
      if nextTarget != 0 [
        ;;show (word "Moving to app with score " score)
        report nextTarget
      ]

      ; Check desktop app neighbor with the current score
      set nextTarget desktop-app-neighbor-with-score score
      if nextTarget != 0 [
        ;;show (word "Moving to desktop-app with score " score)
        report nextTarget
      ]

      ; Check workstation neighbor with the current score
      set nextTarget workstation-neighbor-with-score score
      if nextTarget != 0 [
        ;;show (word "Moving to workstation with score " score)
        report nextTarget
      ]

      ; Increment the score for the next iteration
      set score score + 1
    ]

    ]
    ;; IF CURRENTLY ON APPLICATION
    ( [type1] of currentNode = ["app"])[
     ;;show (word "Currently on app, so no reachable neighbors")
    ;; no legal moves from app for nginx we should consider adding if app allows continue to other app
     report 0
    ]

    ;; IF CURRENTLY ON SERVER
    ( [type1] of currentNode = ["server"])[
    ;;show "Currently on node with type server"
    let score 0
    while [score <= 3] [


    ;; if have root try to find database of connected apps HMM Not implenting as it is same idea as below

    ;; if have root find if connected database
        if check-if-priv-for-node list-of-access one-of [label] of currentNode 2 [
        set nextTarget database-neighbor-with-score score
        if nextTarget != 0 [
          ;;show (word "Moving to database with score " score)
          report nextTarget
        ]
      ]

    ;; if have root try to find other app of connected apps
    if check-if-priv-for-node list-of-access one-of [label] of currentNode 2 [
        let neighboringApps [link-neighbors with [ type1 = "app"]] of location
        set nextTarget neighbor-app-of-connected-app-with-score score neighboringApps
        ;;show (word "Have root ! Finding neighbor of owned apps with score " score)
        if nextTarget != 0 [
         ;;show (word "Moving to app neighbor of connected app with score " score)
          report nextTarget
        ]
      ]

    ;; check connected apps

      set nextTarget app-neighbor-with-score score
        ;;show (word "Finding app neighbor with score " score)
      if nextTarget != 0 [
        ;;show (word "Moving to app neighbor with score " score)
        report nextTarget
      ]
      ; Increment the score for the next iteration
      set score score + 1
      ]

    ]    ;; IF CURRENTLY ON DATABASE
    ( [type1] of currentNode = ["database"])[
      ;;show "ATTACKER ON DATABASE WOW"
    ]    ;; IF CURRENTLY ON CLOUD
    ( [type1] of currentNode = ["cloud"])[
      ;;show "ATTACKER ON CLOUD WOW"
    ]
    )
  report nobody
end


;; when moving reset stuck counters? or atleast globalStuckCount
to stuckHandler
  if location = prevprevlocation [
    ;;show "Seems attacker made a cyclic loop"
    increment-child-table-score list-of-access [label] of location ;; increment score to discourage looping paths
  ]
  ifelse stuckDetector = location [
    set stuckCount stuckCount + 1 ;;show (word "Seems attacker is stuck " stuckCount)
  ][
    set stuckCount 0
  ]
  if (stuckCount >= 3)[                                    ;;; Replace this with patience
    ;;show (word "Attacker got stuck more than thrice on " [label] of location " moving one node back")
      increment-child-table-score list-of-access [label] of location ;; score goes up
      set stuckCount 0
      if prevStuckLabel = [label] of location [
      ;; got stuck on the same node in a row
       set globalStuckCount globalStuckCount + 1
      ]
      set prevStuckLabel [label] of location
      set stuckDetector 0
    if prevprevlocation != 0 [
      if [isSource] of prevLocation != true [
        set location prevLocation
        move-to prevLocation
        set prevLocation prevprevLocation
      ]
    ]
  ]
  set stuckDetector location

  (ifelse
    (globalglobalStuckCount >= 5)[
      ;;show (word "Attacker globally globally got stuck on " globalStuckCount " time(s)")
      ;;show "Attacker has lost motivation and unfortunately our attacker dies"
      set diedAgents diedAgents + 1
      die
    ]
  (globalStuckCount >= 2)[
      ;;show (word "Attacker globally got stuck on " globalStuckCount " time(s)")
      set globalglobalStuckCount globalglobalStuckCount + 1
      set globalStuckCount 0
      ifelse prevprevLocation = 0 [
        ;;show "Attacker has no more nodes to go back on, unfortunately our attacker dies"
        set diedAgents diedAgents + 1
        die
      ][
        ;;show "Attacker got globally stuck 2 times going back one more node"
        if [isSource] of prevLocation != true [
          set prevLocation location
          set location prevprevLocation
          move-to prevprevLocation
          set prevprevLocation 0
        ]
    ]]
  )
end

to give-up
  ;; RANDOM CHANGE TO GIVE UP
  if random skill = 0 [
    set diedAgents diedAgents + 1
    die
  ]
  if random skill = 0 [
    set diedAgents diedAgents + 1
    die
  ]
  if random skill = 0 [
    set diedAgents diedAgents + 1
    die
  ]
end

to add-to-path [newLocation]
  ; Check if pathTaken is a table
  let isTable false
  carefully [ if table:length pathTaken >= 0 [ set isTable true ] ] [ set isTable false ]

  ; If pathTaken is not a table, then initialize it
  if not isTable [
    set pathTaken table:make
  ]

  ; Calculate the next index value
  let nextIndex 1  ; Start from 1 if the table is empty
  if table:length pathTaken > 0 [
    ; Find the highest value in the table and add 1
    set nextIndex (max (table:values pathTaken)) + 1
  ]

  ; Add the new location with its index to the pathTaken table
  table:put pathTaken newLocation nextIndex
end

to wrapped-move-to [nextNode]
   if nextNode != 0 [
    ;;show ( word "Moving to " [label] of nextNode )
   move-to nextNode
   set prevprevLocation prevLocation
   set prevLocation location
   set location one-of turtles-here with [type1 != "attacker"]
   add-to-path [label] of nextNode
  ]
end

to exploitLocal [attackerName]
    let attackerSkill 0
    ;; if attacker is not on isSource true, it tries to exploit its current location
        ask location [
        let nodeLabel label
        let currentPriv -1
        ask one-of attackers with [ label = attackerName ] [
        set currentPriv highest-priv-on-node list-of-access nodeLabel
        set attackerSkill skill
    ]
        ;;show (word "Attempting to exploit current location " label )
        exploit attackerSkill currentPriv attackerName
     ]

end

to exploitReachableNeighbours [attackerName reachableNeighbours]
  ; Iterate over each reachable neighbour
  foreach sort reachableNeighbours [
    [neighbour] ->
    ask neighbour [
      let nodeLabel label
      let currentPriv -1

      ; Ask the attacker to determine the highest privilege on this node
      ask one-of attackers with [label = attackerName] [
        set currentPriv highest-priv-on-node list-of-access nodeLabel
      ]

      if currentPriv = "Child table does not exist"[
         set currentPriv getLowestLevel accessLevels
         setCurrentPrivilege attackerName [label] of neighbour currentPriv

      ]

      ; Output attempt information
      ;;show (word "Attempting to exploit reachable neighbor " label)
      ; Call the exploit procedure with relevant parameters
      exploit skill currentPriv attackerName
    ]
  ]
end


to-report get-reachable-neighbors [attackerName]
  let currentNode one-of turtles-here with [type1 != "attacker"]
  let reachable-neighbors nobody

  ; Check the type of the current node and accumulate reachable neighbors accordingly
 (ifelse
    ;; IF CURRENTLY ON SOURCE
    ([isSource] of currentNode) [
    ; If currently on a source, can reach databases, servers, and apps
      set reachable-neighbors (out-link-neighbors with [type1 = "database" or type1 = "server" or type1 = "app" or type1 = "desktop-app" or type1 = "workstation"])

    ] ([type1] of currentNode = "app") [
          ;;show reachable-neighbors
         ; Move to app if have other_app permission
         if has-permission? attackerName [label] of currentNode "other_app" [ ;; IF HAVE OTHER APP
           let appNeighbors ([out-link-neighbors] of currentNode) with [type1 = "app"]
           set reachable-neighbors (turtle-set appNeighbors)
         ]
         ; Move to server if have server permission
        if has-permission? attackerName [label] of currentNode "server" [ ;; IF HAVE SERVER
           let svNeighbors ([link-neighbors] of currentNode) with [type1 = "server"]
           set reachable-neighbors (turtle-set svNeighbors)
         ]
        ; Move to database if have database permission
        if has-permission? attackerName [label] of currentNode "database" [ ;; IF HAVE OTHER APP
           let dbNeighbors ([out-link-neighbors] of currentNode) with [type1 = "database"]
           set reachable-neighbors (turtle-set dbNeighbors)
         ]
         ;;show reachable-neighbors
    ] ([type1] of currentNode = "server") [
           ; Can reach connected apps, and more if server has root
           let appNeighbors ([out-link-neighbors] of currentNode) with [type1 = "app"]
           set reachable-neighbors (turtle-set reachable-neighbors appNeighbors)
           if has-permission? attackerName [label] of currentNode "root" [ ;; IF HAVE ROOT
             ; Add neighbors of connected apps and databases if server has root
             ask appNeighbors [
               ; For each app neighbor, get its link-neighbors
               let neighbor-link-neighbors out-link-neighbors
               ; Check the type of each link-neighbor
               ask neighbor-link-neighbors [
                 if type1 = "app" or type1 = "database" [
                   ; Add to the reachable-neighbors set
                   set reachable-neighbors (turtle-set reachable-neighbors self)
                 ]
               ]
             ]
           ]
      ]([type1] of currentNode = "desktop-app") [
           ; Can reach connected apps, and if have workstation privilege on desktop-app then access to workstation

           if has-permission? attackerName [label] of currentNode "other_app" [ ;; IF HAVE other_app
           let appNeighbors ([out-link-neighbors] of currentNode) with [type1 = "app"]
           set reachable-neighbors (turtle-set reachable-neighbors appNeighbors)
           ]
           if has-permission? attackerName [label] of currentNode "workstation" [ ;; IF HAVE WORKSTATION ;;;;; HERE HERE HERE
             ; Add workstation if we have workstation permission on desktop-app
             let workstationNeighbor ([link-neighbors] of currentNode) with [type1 = "workstation"]
             set reachable-neighbors (turtle-set reachable-neighbors workstationNeighbor)
           ]
      ]([type1] of currentNode = "workstation") [
          ;;show list-of-access
           ; Can reach to desktop apps if have root can access other apps or databases connected to this app
           let DappNeighbors ([link-neighbors] of currentNode) with [type1 = "desktop-app"]
           set reachable-neighbors (turtle-set reachable-neighbors DappNeighbors)
           if has-permission? attackerName [label] of currentNode "root" [ ;; IF HAVE ROOT
             ; Add neighbors of connected Dapps if worstation has root
             ask DappNeighbors [
               ; For each desktop app neighbor, get its link-neighbors
               let neighbor-link-neighbors out-link-neighbors
               ; Check the type of each link-neighbor
               ask neighbor-link-neighbors [
                 if type1 = "app" or type1 = "database" [
                   ; Add to the reachable-neighbors set
                   set reachable-neighbors (turtle-set reachable-neighbors self)
                 ]
               ]
             ]
           ]
      ]
    )
  report reachable-neighbors
end

to move-node-final [attackerName nextTarget]

     if nextTarget != 0 and nextTarget != nobody [
       ask nextTarget [
          let nodeLabel label
          let currentLevel getLowestLevel accessLevels
          let currentPriv -1
          ask one-of attackers with [ label = attackerName ] [
          setCurrentPrivilege attackerName nodeLabel currentLevel
          set currentPriv highest-priv-on-node list-of-access nodeLabel
    ]]
       wrapped-move-to nextTarget
     ]
end

to move-node [attackerName]
     let nextTarget move-legal label

     if nextTarget != 0 and nextTarget != nobody [
       ask nextTarget [
          let nodeLabel label
          let currentLevel getLowestLevel accessLevels
          let currentPriv -1
          ask one-of attackers with [ label = attackerName ] [
          setCurrentPrivilege attackerName nodeLabel currentLevel
          set currentPriv highest-priv-on-node list-of-access nodeLabel
    ]]
       wrapped-move-to nextTarget
     ]
end

to-report get-list-of-possible-moves [attackerName]
  let currentNode one-of turtles-here with [type1 != "attacker"]
  let nodeLabel [label] of currentNode
  let attackerPrivileges [list-of-access] of one-of attackers with [label = attackerName]
  ; Initialize possibleMoves with reachable neighbors
  let possibleMoves get-reachable-neighbors attackerName
  if possibleMoves = nobody [ set possibleMoves no-turtles ]
  if table:has-key? attackerPrivileges nodeLabel [
    let currentPrivileges table:get attackerPrivileges nodeLabel
    let currentAccessLevels [accessLevels] of currentNode

    foreach table:keys currentPrivileges [
      [priv] ->
      if is-number? priv [
        let privString table:get currentAccessLevels priv

        ; Add server neighbors if privilege is 'server' and current node is app
        if (privString = "server" and [type1] of currentNode = "app") [
          let serverNeighbors ([out-link-neighbors] of currentNode) with [type1 = "server"]
          set possibleMoves (turtle-set possibleMoves serverNeighbors)
        ]

        ; Add app neighbors if privilege is 'other_app'
        if (privString = "other_app" and [type1] of currentNode = "app") [
          let appNeighbors ([out-link-neighbors] of currentNode) with [type1 = "app"]
          set possibleMoves (turtle-set possibleMoves appNeighbors)
        ]
         ; Add database neighbors if privilege is 'database' and current node is app
        if (privString = "database" and [type1] of currentNode = "app") [
          let dbNeighbors ([out-link-neighbors] of currentNode) with [type1 = "database"]
          set possibleMoves (turtle-set possibleMoves dbNeighbors)
        ]

      ]
    ]
  ]
  report possibleMoves
end

to-report key-in-child-table? [parentTable nodeLabel key]
  if not table:has-key? parentTable nodeLabel [
    report false
  ]
  let childTable table:get parentTable nodeLabel
  report table:has-key? childTable key
end

to-report decide-best-move [list-of-possible-moves copy-list-of-access]
  ; Check if there are any database type nodes, return the first one found
  foreach sort list-of-possible-moves [
    [node] ->
    if [type1] of node = "database" [
      report node
    ]
  ]
 ;;show list-of-possible-moves
 ;;show copy-list-of-access
  ; Check for server and app nodes with scores from 0 to 10
  let scores [0 1 2 3 4 5 6 7 8 9 10]  ; Define the score range
  foreach scores [
    [score] ->
    ; Check for server with the current score
    foreach sort list-of-possible-moves [
      [node] ->
      if ([type1] of node = "server" and get-child-table-score copy-list-of-access [label] of node = score) [
        report node
      ]
    ]

    ; Check for app with the current score
    foreach sort list-of-possible-moves [
      [node] ->
      if ([type1] of node = "app" and get-child-table-score copy-list-of-access [label] of node = score) [
        report node
      ]
    ]

    ; Check for desktop app with the current score
    foreach sort list-of-possible-moves [
      [node] ->
      if ([type1] of node = "desktop-app" and get-child-table-score copy-list-of-access [label] of node = score) [
        report node
      ]
    ]
    ; Check for workstation with the current score
    foreach sort list-of-possible-moves [
      [node] ->
      if ([type1] of node = "workstation" and get-child-table-score copy-list-of-access [label] of node = score) [
        report node
      ]
    ]
  ]

  ; If no node meets the criteria, report nobody
  report nobody
end


to step [attackerName]
   ask one-of attackers with [label = attackerName] [
    ifelse [label] of location != goalLabel [
      if [isSource] of location != true [
        ;;show (word "Currently on " [label] of location)
        exploitLocal attackerName
        ;;show "exploiting reachableNeighbours"
        let reachableNeigbours get-reachable-neighbors attackerName
        ifelse reachableNeigbours != nobody and count reachableNeigbours != 0 [
          ;;show [label] of reachableNeigbours
          exploitReachableNeighbours attackerName reachableNeigbours
        ][
          ;;show reachableNeigbours
        ]
      ]



      ifelse [isSource] of location = true [
        move-node attackerName
      ][
        ;; get list of possible moves
        let list-of-possible-moves get-list-of-possible-moves attackerName

        if count list-of-possible-moves != 0 [
          ;; decide which node is best to move
          let nextNode decide-best-move list-of-possible-moves list-of-access
          ;; move
         ;;show nextNode

          move-node-final attackerName nextNode
        ]
      ]

    stuckHandler
    give-up
    ][
    ;;show "Goal reached"
      if startLabel = "Web User"[
        set WebNodes WebNodes + 1
        if skill > 50 and skill < 80 [
          set threatEvent1 threatEvent1 + 1
        ]
         if skill > 80 [
          set threatEvent2 threatEvent2 + 1
        ]
      ]
      if startLabel = "Shop User"[
        set ShopNodes ShopNodes + 1
        if skill > 50 and skill < 80 [
          set threatEvent1 threatEvent1 + 1
        ]
        if skill > 80 [
          set threatEvent2 threatEvent2 + 1
        ]
      ]
      if startLabel = "Employee User"[
         if skill < 50 [
        set EmployeeNodes EmployeeNodes + 1
        set threatEvent3 threatEvent3 + 1
        ]
      ]
    set successfulGoals successfulGoals + 1
    die
    ]
  ]
end

to init-attackers-with-skill [num-attackers atSkill]
  set totalAgents totalAgents + num-attackers
  let i 1
  while [i <= num-attackers] [

    create-attackers 1 [
      set type1 "attacker"
      set label (word "attacker" ticks who)
      set list-of-access table:make
      set exploitedCVEs table:make
      set exploitedMisconfigs table:make
      set color red
      set skill atSkill  ; Skill between 1 and 100
      ifelse random 30 = 0 [
      set location one-of turtles with [isSource = true and internal = true]
      ][
        set location one-of turtles with [isSource = true and internal != true]
      ]
      if atSkill > 80 and [label] of location != "Employee User" [
        set attackerState attackerState + 1
      ]
      if atSkill > 60 and atSkill < 80 and [label] of location != "Employee User" [
        set attackerModerateToHigh attackerModerateToHigh + 1
      ]
      if atSkill < 40 and [label] of location = "Employee User" [
        set attackerLowSkill attackerLowSkill + 1
        set color green
        set size 2
      ]
      set startLabel [label] of location
      set prevLocation 0
      set goalLabel "Database"
      move-to location
    ]
    set i i + 1
  ]
end

to step-all-attackers
  let attacker-labels [label] of attackers
  foreach attacker-labels [A-label ->
    step A-label
  ]
end

to set-company-trend
 set companyTrend random 2
end

to set-company-trend-positive
 set companyTrend random 1
end

to set-company-trend-negative
 set companyTrend random 0
end


to change-company-score
  if companyScore < 1 [
    set companyScore companyScore + 1
  ]
  if companyScore > 50 [
      set companyScore companyScore - 1
  ]
  ifelse companyTrend = 1 [set companyScore companyScore + 1][set companyScore companyScore - 1]
end

to-report check-active-vulnerabilities [nodeLabel]
  ; Find the node with the given label
  let target-node one-of turtles with [label = nodeLabel]
  if target-node = nobody [
    report 0  ; Return 0 if the node doesn't exist
  ]

  ; Get the known vulnerabilities of the target node
  let vulnerabilities [knownVulnerabilities] of target-node
  let active-count 0

  ; Iterate through each vulnerability and check if it exists
  foreach (table:keys vulnerabilities) [
    [vulnerability] ->
    let details table:get vulnerabilities vulnerability
    if table:get details "Exists" [
      ; Count the active vulnerability
      set active-count active-count + 1
    ]
  ]

  ; Report the count of active vulnerabilities
  report active-count
end

to-report check-active-misconfigs [nodeLabel]
  ; Find the node with the given label
  let target-node one-of turtles with [label = nodeLabel]
  if target-node = nobody [
    report 0  ; Return 0 if the node doesn't exist
  ]

  ; Get the misconfigurations of the target node
  let misconfigs [potentialMisconfigs] of target-node
  let active-count 0

  ; Iterate over each misconfiguration and check if it's active
  foreach (table:keys misconfigs) [
    [misconfig] ->
    let details table:get misconfigs misconfig
    if table:get details "Exists" [
      ; Count the active misconfiguration
      set active-count active-count + 1
    ]
  ]

  ; Report the count of active misconfigurations
  report active-count
end



to-report count-total-misconfigs [nodeLabel]
  ;; Find the node with the given label
  let target-node one-of turtles with [label = nodeLabel]
  if target-node = nobody [
    report 0  ; Return 0 if the node doesn't exist
  ]

  ;; Retrieve the potentialMisconfigs table of the target node
  let misconfigs-table [potentialMisconfigs] of target-node

  ;; Count the total number of keys in the misconfigs-table
  report table:length misconfigs-table
end


to-report count-total-cves [nodeLabel]
  ;; Find the node with the given label
  let target-node one-of turtles with [label = nodeLabel]
  if target-node = nobody [
    report 0  ; Return 0 if the node doesn't exist
  ]

  ;; Retrieve the knownVulnerabilities table of the target node
  let cves-table [knownVulnerabilities] of target-node

  ;; Return the number of keys (CVEs) in the table
  report table:length cves-table
end




to go
  if (random 3 = 0)[
  set-company-trend
  ]
  change-company-score

    ;; check company score
  (ifelse
      companyScore < 10 [
      if random 2 = 0 [
      init-attackers-with-skill 1 random 40 + 1 ;; attacker with low skill
      ]
      if random 3 = 2 [
      init-attackers-with-skill 1 random 80 + 1 ;; attacker with random skill but not very high
      ]
      ]
      companyScore >= 10 and companyScore < 20 [
      if random 2 = 0 [
      init-attackers-with-skill 1 random 40 + 1 ;; two attackers with low skill
      ]
      if random 3 = 2 [
      init-attackers-with-skill 1 random 80 + 1 ;; attacker with random skill but not very high
      ]
      ]
      companyScore >= 20 and companyScore < 30 [
       if random 2 = 0 [
      init-attackers-with-skill 1 random 50 + 1 ;; two attackers with possible medium skill
      ]
      if random 3 = 2 [
      init-attackers-with-skill 1 random 100 + 1 ;; attacker with random skill
      ]
      ]
      companyScore >= 30 and companyScore < 40 [
      if random 4 = 0 [
      init-attackers-with-skill 1 random 70 + 1 ;; attacker with possible higher skill
      ]
      init-attackers-with-skill 1 random 70 + 1 ;; attacker with possible higher skill
      if random 3 = 2 [
      init-attackers-with-skill 1 (80 + random 21) ;; two state sponsored attackers
      ]
      ]
      companyScore >= 40 and companyScore <= 50[
      if random 4 = 0 [
      init-attackers-with-skill 2 random 70 + 1 ;; one attacker with higher skill
      ]
      init-attackers-with-skill 2 random 70 + 1 ;; three attacker with possible higher skill
      if random 2 = 1 [
      init-attackers-with-skill 1 (80 + random 21) ;; two state sponsored attackers
      ]
      ]
    )
    ;; create attackers
    step-all-attackers
    if count attackers > 0 [
      tick
    ]
  update-vulnerabilities
end

to go-global-static
  clear-all
  reset-ticks
  set newApp false
  set isStatic true
  set releaseScenario false
  setup
  while [ticks < 366] [
   go
  ]
  print (word "Threat event 1, medium to high "threatEvent1 )
  print (word "Attacker Medium to high skill " attackerModerateToHigh)
  print (word "Threat event 2, state sponsored " threatEvent2)
  print (word "Attacker state number " attackerState)
  print ( word "Threat event 3, internal low " threatEvent3 )
  print (word "Attacker Low skill " attackerLowSkill)

end

to go-global-dynamic
  clear-all
  reset-ticks
  set newApp false
  set isStatic false
  set releaseScenario false
  setup
  while [ticks < 366] [
   go
  ]
  print (word "Threat event 1, medium to high "threatEvent1 )
  print (word "Attacker Medium to high skill " attackerModerateToHigh)
  print (word "Threat event 2, state sponsored " threatEvent2)
  print (word "Attacker state number " attackerState)
  print ( word "Threat event 3, internal low " threatEvent3 )
  print (word "Attacker Low skill " attackerLowSkill)

end
    