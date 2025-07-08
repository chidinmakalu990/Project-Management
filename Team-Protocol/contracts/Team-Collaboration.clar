;; Decentralized Team Collaboration Platform Smart Contract
;; A comprehensive blockchain-based platform for managing distributed teams,
;; automating project workflows, tracking performance metrics, and facilitating
;; trustless payments between collaborators with built-in reputation systems

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-PROJECT-NOT-FOUND (err u101))
(define-constant ERR-TASK-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS-CHANGE (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-PROJECT-ALREADY-EXISTS (err u105))
(define-constant ERR-TASK-ALREADY-EXISTS (err u106))
(define-constant ERR-INVALID-PARAMETERS (err u107))
(define-constant ERR-MEMBER-ALREADY-ADDED (err u108))
(define-constant ERR-TEAM-SIZE-LIMIT-EXCEEDED (err u109))

;; CONFIGURATION CONSTANTS

(define-constant MAX-TEAM-SIZE u20)
(define-constant MIN-RATING-SCORE u1)
(define-constant MAX-RATING-SCORE u5)
(define-constant PROJECT-COUNTER-KEY "projects")
(define-constant ACTIVE-PROJECT-STATUS "active")
(define-constant PENDING-TASK-STATUS "pending")
(define-constant COMPLETED-TASK-STATUS "completed")

;; DATA STRUCTURES

;; Main project registry storing all collaborative projects
(define-map project-registry
    { project-identifier: uint }
    {
        owner-principal: principal,
        project-title: (string-ascii 50),
        project-description: (string-ascii 500),
        total-budget: uint,
        status: (string-ascii 20),
        creation-block: uint,
        team-members: (list 20 principal)
    }
)

;; Task management system for tracking individual assignments
(define-map task-registry
    { project-identifier: uint, task-identifier: uint }
    {
        assignee-principal: principal,
        task-title: (string-ascii 50),
        task-description: (string-ascii 500),
        deadline-block: uint,
        compensation: uint,
        status: (string-ascii 20),
        creation-block: uint
    }
)

;; Global counters for generating unique identifiers
(define-map identifier-counters
    { counter-type: (string-ascii 10) }
    { current-value: uint }
)

;; Project-specific task counters
(define-map project-task-counters
    { project-identifier: uint }
    { next-task-number: uint }
)

;; Performance analytics for team members
(define-map member-analytics
    { member-principal: principal }
    {
        completed-tasks: uint,
        total-earnings: uint,
        average-rating: uint,
        rating-count: uint
    }
)

;; VALIDATION UTILITIES

;; Verify project ownership
(define-private (is-project-owner (project-id uint) (caller principal))
    (match (map-get? project-registry { project-identifier: project-id })
        project-data (is-eq (get owner-principal project-data) caller)
        false
    )
)

;; Check if caller has project access (owner or team member)
(define-private (has-project-access (project-id uint) (caller principal))
    (match (map-get? project-registry { project-identifier: project-id })
        project-data (or
            (is-eq (get owner-principal project-data) caller)
            (is-some (index-of (get team-members project-data) caller))
        )
        false
    )
)

;; Validate project creation parameters
(define-private (validate-project-params (title (string-ascii 50)) 
                                        (description (string-ascii 500)) 
                                        (budget uint))
    (and 
        (> (len title) u0)
        (> (len description) u0)
        (> budget u0)
    )
)

;; Validate task creation parameters
(define-private (validate-task-params (project-data {owner-principal: principal, 
                                                    project-title: (string-ascii 50),
                                                    project-description: (string-ascii 500),
                                                    total-budget: uint,
                                                    status: (string-ascii 20),
                                                    creation-block: uint,
                                                    team-members: (list 20 principal)})
                                     (title (string-ascii 50))
                                     (description (string-ascii 500))
                                     (assignee principal)
                                     (deadline uint)
                                     (payment uint))
    (and 
        (> (len title) u0)
        (> (len description) u0)
        (> deadline block-height)
        (> payment u0)
        (or
            (is-eq assignee (get owner-principal project-data))
            (is-some (index-of (get team-members project-data) assignee))
        )
    )
)

;; Comprehensive input validation
(define-private (validate-inputs (title-opt (optional (string-ascii 50)))
                                (description-opt (optional (string-ascii 500)))
                                (budget-opt (optional uint))
                                (project-id-opt (optional uint))
                                (task-id-opt (optional uint))
                                (status-opt (optional (string-ascii 20)))
                                (principal-opt (optional principal))
                                (rating-opt (optional uint)))
    (let ((title-valid (match title-opt
                         some-title (> (len some-title) u0)
                         true))
          (description-valid (match description-opt
                              some-desc (> (len some-desc) u0)
                              true))
          (budget-valid (match budget-opt
                         some-budget (> some-budget u0)
                         true))
          (project-id-valid (match project-id-opt
                             some-id (>= some-id u0)
                             true))
          (task-id-valid (match task-id-opt
                          some-id (>= some-id u0)
                          true))
          (status-valid (match status-opt
                         some-status (> (len some-status) u0)
                         true))
          (rating-valid (match rating-opt
                         some-rating (and (>= some-rating MIN-RATING-SCORE) 
                                         (<= some-rating MAX-RATING-SCORE))
                         true)))
        (and title-valid description-valid budget-valid 
             project-id-valid task-id-valid status-valid rating-valid)))

;; ID GENERATION UTILITIES

;; Generate unique project identifier
(define-private (generate-project-id)
    (let ((counter-data (default-to { current-value: u0 } 
                                   (map-get? identifier-counters { counter-type: PROJECT-COUNTER-KEY }))))
        (begin
            (map-set identifier-counters 
                    { counter-type: PROJECT-COUNTER-KEY } 
                    { current-value: (+ (get current-value counter-data) u1) })
            (get current-value counter-data)
        )
    )
)

;; Generate unique task identifier for a project
(define-private (generate-task-id (project-id uint))
    (match (map-get? project-registry { project-identifier: project-id })
        project-data 
            (let ((task-counter (default-to { next-task-number: u0 } 
                                           (map-get? project-task-counters { project-identifier: project-id }))))
                (begin
                    (map-set project-task-counters 
                            { project-identifier: project-id } 
                            { next-task-number: (+ (get next-task-number task-counter) u1) })
                    (ok (get next-task-number task-counter))
                )
            )
        ERR-PROJECT-NOT-FOUND
    )
)

;; CORE PROJECT MANAGEMENT FUNCTIONS

;; Create a new collaborative project
(define-public (create-project (project-title (string-ascii 50)) 
                              (project-description (string-ascii 500)) 
                              (project-budget uint))
    (let ((new-project-id (generate-project-id))
          (project-creator tx-sender))
        (asserts! (validate-inputs (some project-title) (some project-description) 
                                  (some project-budget) none none none none none) 
                 ERR-INVALID-PARAMETERS)
        (asserts! (validate-project-params project-title project-description project-budget)
                 ERR-INVALID-PARAMETERS)
        (map-set project-registry
            { project-identifier: new-project-id }
            {
                owner-principal: project-creator,
                project-title: project-title,
                project-description: project-description,
                total-budget: project-budget,
                status: ACTIVE-PROJECT-STATUS,
                creation-block: block-height,
                team-members: (list)
            }
        )
        (ok new-project-id)
    )
)

;; Add team member to project
(define-public (add-team-member (project-id uint) (new-member principal))
    (let ((caller tx-sender))
        (asserts! (validate-inputs none none none (some project-id) 
                                  none none (some new-member) none)
                 ERR-INVALID-PARAMETERS)
        (match (map-get? project-registry { project-identifier: project-id })
            project-data
                (begin
                    (asserts! (is-eq (get owner-principal project-data) caller)
                             ERR-UNAUTHORIZED-ACCESS)
                    (asserts! (is-none (index-of (get team-members project-data) new-member))
                             ERR-MEMBER-ALREADY-ADDED)
                    (asserts! (< (len (get team-members project-data)) MAX-TEAM-SIZE)
                             ERR-TEAM-SIZE-LIMIT-EXCEEDED)
                    (let ((updated-team-list (unwrap! (as-max-len? 
                                                      (append (get team-members project-data) new-member) 
                                                      u20) 
                                                     ERR-TEAM-SIZE-LIMIT-EXCEEDED)))
                        (map-set project-registry
                            { project-identifier: project-id }
                            (merge project-data { team-members: updated-team-list })
                        )
                        (ok true)
                    )
                )
            ERR-PROJECT-NOT-FOUND
        )
    )
)

;; TASK MANAGEMENT FUNCTIONS

;; Create and assign a task
(define-public (create-task (project-id uint)
                           (task-title (string-ascii 50))
                           (task-description (string-ascii 500))
                           (assignee principal)
                           (deadline uint)
                           (payment uint))
    (let ((caller tx-sender))
        (asserts! (validate-inputs (some task-title) (some task-description) 
                                  (some payment) (some project-id) 
                                  none none (some assignee) none)
                 ERR-INVALID-PARAMETERS)
        (asserts! (> deadline block-height) ERR-INVALID-PARAMETERS)
        (match (map-get? project-registry { project-identifier: project-id })
            project-data
                (begin
                    (asserts! (is-eq (get owner-principal project-data) caller)
                             ERR-UNAUTHORIZED-ACCESS)
                    (asserts! (validate-task-params project-data 
                                                   task-title 
                                                   task-description 
                                                   assignee 
                                                   deadline 
                                                   payment)
                             ERR-INVALID-PARAMETERS)
                    (match (generate-task-id project-id)
                        task-id
                            (begin
                                (map-set task-registry
                                    { project-identifier: project-id, task-identifier: task-id }
                                    {
                                        assignee-principal: assignee,
                                        task-title: task-title,
                                        task-description: task-description,
                                        deadline-block: deadline,
                                        compensation: payment,
                                        status: PENDING-TASK-STATUS,
                                        creation-block: block-height
                                    }
                                )
                                (ok task-id)
                            )
                        error-response ERR-PROJECT-NOT-FOUND
                    )
                )
            ERR-PROJECT-NOT-FOUND
        )
    )
)

;; Update task status
(define-public (update-task-status (project-id uint) 
                                  (task-id uint) 
                                  (new-status (string-ascii 20)))
    (let ((caller tx-sender))
        (asserts! (validate-inputs none none none (some project-id) 
                                  (some task-id) (some new-status) none none)
                 ERR-INVALID-PARAMETERS)
        (match (map-get? project-registry { project-identifier: project-id })
            project-data
                (match (map-get? task-registry { project-identifier: project-id, task-identifier: task-id })
                    task-data
                        (begin
                            (asserts! (or (is-eq (get owner-principal project-data) caller) 
                                         (is-eq (get assignee-principal task-data) caller))
                                     ERR-UNAUTHORIZED-ACCESS)
                            (map-set task-registry
                                { project-identifier: project-id, task-identifier: task-id }
                                (merge task-data { status: new-status })
                            )
                            (ok true)
                        )
                    ERR-TASK-NOT-FOUND
                )
            ERR-PROJECT-NOT-FOUND
        )
    )
)

;; Complete task and process payment
(define-public (complete-task (project-id uint) (task-id uint))
    (let ((caller tx-sender))
        (asserts! (validate-inputs none none none (some project-id) 
                                  (some task-id) none none none)
                 ERR-INVALID-PARAMETERS)
        (match (map-get? project-registry { project-identifier: project-id })
            project-data
                (match (map-get? task-registry { project-identifier: project-id, task-identifier: task-id })
                    task-data
                        (begin
                            (asserts! (is-eq (get assignee-principal task-data) caller)
                                     ERR-UNAUTHORIZED-ACCESS)
                            (asserts! (is-eq (get status task-data) PENDING-TASK-STATUS)
                                     ERR-INVALID-STATUS-CHANGE)
                            ;; Transfer payment
                            (try! (stx-transfer? (get compensation task-data) 
                                               (get owner-principal project-data) 
                                               caller))
                            ;; Update task status
                            (map-set task-registry
                                { project-identifier: project-id, task-identifier: task-id }
                                (merge task-data { status: COMPLETED-TASK-STATUS })
                            )
                            ;; Update member analytics
                            (update-member-performance caller (get compensation task-data))
                            (ok true)
                        )
                    ERR-TASK-NOT-FOUND
                )
            ERR-PROJECT-NOT-FOUND
        )
    )
)

;; PERFORMANCE MANAGEMENT FUNCTIONS

;; Update member performance metrics
(define-private (update-member-performance (member principal) (earnings uint))
    (let ((current-analytics (default-to
            { completed-tasks: u0, total-earnings: u0, average-rating: u0, rating-count: u0 }
            (map-get? member-analytics { member-principal: member })
        )))
        (map-set member-analytics
            { member-principal: member }
            {
                completed-tasks: (+ (get completed-tasks current-analytics) u1),
                total-earnings: (+ (get total-earnings current-analytics) earnings),
                average-rating: (get average-rating current-analytics),
                rating-count: (get rating-count current-analytics)
            }
        )
    )
)

;; Submit performance rating
(define-public (rate-member (member principal) (rating uint))
    (begin
        (asserts! (validate-inputs none none none none none none 
                                  (some member) (some rating))
                 ERR-INVALID-PARAMETERS)
        (let ((current-analytics (default-to
                { completed-tasks: u0, total-earnings: u0, average-rating: u0, rating-count: u0 }
                (map-get? member-analytics { member-principal: member })
            )))
            (map-set member-analytics
                { member-principal: member }
                {
                    completed-tasks: (get completed-tasks current-analytics),
                    total-earnings: (get total-earnings current-analytics),
                    average-rating: (/ (+ (* (get average-rating current-analytics) 
                                           (get rating-count current-analytics)) 
                                        rating) 
                                     (+ (get rating-count current-analytics) u1)),
                    rating-count: (+ (get rating-count current-analytics) u1)
                }
            )
            (ok true)
        )
    )
)

;; READ-ONLY QUERY FUNCTIONS

;; Get project details
(define-read-only (get-project-details (project-id uint))
    (begin
        (asserts! (validate-inputs none none none (some project-id) 
                                  none none none none) 
                 none)
        (map-get? project-registry { project-identifier: project-id })
    )
)

;; Get task details
(define-read-only (get-task-details (project-id uint) (task-id uint))
    (begin
        (asserts! (validate-inputs none none none (some project-id) 
                                  (some task-id) none none none)
                 none)
        (map-get? task-registry { project-identifier: project-id, task-identifier: task-id })
    )
)

;; Get member performance analytics
(define-read-only (get-member-analytics (member principal))
    (map-get? member-analytics { member-principal: member })
)

;; Check project access permissions
(define-read-only (check-project-access (project-id uint) (member principal))
    (begin
        (asserts! (validate-inputs none none none (some project-id) 
                                  none none (some member) none)
                 false)
        (has-project-access project-id member)
    )
)

;; Verify project ownership
(define-read-only (verify-project-ownership (project-id uint) (member principal))
    (begin
        (asserts! (validate-inputs none none none (some project-id) 
                                  none none (some member) none)
                 false)
        (is-project-owner project-id member)
    )
)