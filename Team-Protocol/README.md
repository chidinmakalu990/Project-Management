# Decentralized Team Collaboration Platform

A comprehensive blockchain-based platform for managing distributed teams, automating project workflows, tracking performance metrics, and facilitating trustless payments between collaborators with built-in reputation systems.

## Overview

This smart contract enables decentralized project management where teams can collaborate without traditional intermediaries. It provides secure, transparent, and automated workflows for project creation, task assignment, completion tracking, and payment processing.

## Features

### Core Functionality
- **Project Management**: Create and manage collaborative projects with customizable budgets
- **Team Collaboration**: Add team members (up to 20 per project) with role-based access
- **Task Assignment**: Create, assign, and track tasks with deadlines and compensation
- **Automated Payments**: Trustless payment processing upon task completion
- **Performance Analytics**: Track member performance and reputation scores
- **Rating System**: Peer-to-peer rating system for quality assurance

### Security Features
- Role-based access control (project owners vs team members)
- Input validation and parameter checking
- Secure payment transfers using STX tokens
- Protection against common smart contract vulnerabilities

## Smart Contract Architecture

### Data Structures

#### Projects
```clarity
project-registry: {
  project-identifier: uint,
  owner-principal: principal,
  project-title: string-ascii(50),
  project-description: string-ascii(500),
  total-budget: uint,
  status: string-ascii(20),
  creation-block: uint,
  team-members: list(20 principal)
}
```

#### Tasks
```clarity
task-registry: {
  project-identifier: uint,
  task-identifier: uint,
  assignee-principal: principal,
  task-title: string-ascii(50),
  task-description: string-ascii(500),
  deadline-block: uint,
  compensation: uint,
  status: string-ascii(20),
  creation-block: uint
}
```

#### Performance Analytics
```clarity
member-analytics: {
  member-principal: principal,
  completed-tasks: uint,
  total-earnings: uint,
  average-rating: uint,
  rating-count: uint
}
```

## Public Functions

### Project Management

#### `create-project`
Creates a new collaborative project.
```clarity
(create-project project-title project-description project-budget)
```
- **Parameters**: 
  - `project-title`: String up to 50 characters
  - `project-description`: String up to 500 characters
  - `project-budget`: Uint representing total budget in microSTX
- **Returns**: `(ok project-id)` on success
- **Authorization**: Any user can create projects

#### `add-team-member`
Adds a team member to an existing project.
```clarity
(add-team-member project-id new-member)
```
- **Parameters**: 
  - `project-id`: Unique project identifier
  - `new-member`: Principal address of the new team member
- **Returns**: `(ok true)` on success
- **Authorization**: Only project owner
- **Constraints**: Maximum 20 team members per project

### Task Management

#### `create-task`
Creates and assigns a new task within a project.
```clarity
(create-task project-id task-title task-description assignee deadline payment)
```
- **Parameters**: 
  - `project-id`: Target project identifier
  - `task-title`: String up to 50 characters
  - `task-description`: String up to 500 characters
  - `assignee`: Principal address of the task assignee
  - `deadline`: Block height deadline
  - `payment`: Compensation amount in microSTX
- **Returns**: `(ok task-id)` on success
- **Authorization**: Only project owner
- **Constraints**: Assignee must be project owner or team member

#### `update-task-status`
Updates the status of an existing task.
```clarity
(update-task-status project-id task-id new-status)
```
- **Parameters**: 
  - `project-id`: Project identifier
  - `task-id`: Task identifier
  - `new-status`: New status string
- **Returns**: `(ok true)` on success
- **Authorization**: Project owner or task assignee

#### `complete-task`
Marks a task as completed and processes payment.
```clarity
(complete-task project-id task-id)
```
- **Parameters**: 
  - `project-id`: Project identifier
  - `task-id`: Task identifier
- **Returns**: `(ok true)` on success
- **Authorization**: Only task assignee
- **Side Effects**: 
  - Transfers payment from project owner to assignee
  - Updates task status to "completed"
  - Updates assignee's performance metrics

### Performance Management

#### `rate-member`
Submits a performance rating for a team member.
```clarity
(rate-member member rating)
```
- **Parameters**: 
  - `member`: Principal address of the member to rate
  - `rating`: Rating score (1-5)
- **Returns**: `(ok true)` on success
- **Authorization**: Any user
- **Side Effects**: Updates member's average rating and rating count

## Read-Only Functions

### `get-project-details`
Retrieves complete project information.
```clarity
(get-project-details project-id)
```

### `get-task-details`
Retrieves complete task information.
```clarity
(get-task-details project-id task-id)
```

### `get-member-analytics`
Retrieves performance analytics for a member.
```clarity
(get-member-analytics member)
```

### `check-project-access`
Verifies if a member has access to a project.
```clarity
(check-project-access project-id member)
```

### `verify-project-ownership`
Verifies if a member owns a specific project.
```clarity
(verify-project-ownership project-id member)
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-UNAUTHORIZED-ACCESS | Caller lacks required permissions |
| u101 | ERR-PROJECT-NOT-FOUND | Project does not exist |
| u102 | ERR-TASK-NOT-FOUND | Task does not exist |
| u103 | ERR-INVALID-STATUS-CHANGE | Invalid task status transition |
| u104 | ERR-INSUFFICIENT-FUNDS | Insufficient funds for operation |
| u105 | ERR-PROJECT-ALREADY-EXISTS | Project already exists |
| u106 | ERR-TASK-ALREADY-EXISTS | Task already exists |
| u107 | ERR-INVALID-PARAMETERS | Invalid input parameters |
| u108 | ERR-MEMBER-ALREADY-ADDED | Member already in project |
| u109 | ERR-TEAM-SIZE-LIMIT-EXCEEDED | Team size exceeds limit |

## Usage Examples

### Creating a Project
```clarity
(contract-call? .collaboration-platform create-project
  "Website Redesign"
  "Complete redesign of company website with modern UI/UX"
  u1000000) ;; 1 STX budget
```

### Adding Team Members
```clarity
(contract-call? .collaboration-platform add-team-member
  u1 ;; project-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7) ;; member principal
```

### Creating Tasks
```clarity
(contract-call? .collaboration-platform create-task
  u1 ;; project-id
  "Design Homepage"
  "Create responsive homepage design with hero section and navigation"
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 ;; assignee
  u1000 ;; deadline block
  u200000) ;; 0.2 STX payment
```

### Completing Tasks
```clarity
(contract-call? .collaboration-platform complete-task
  u1 ;; project-id
  u1) ;; task-id
```

## Security Considerations

1. **Access Control**: All functions implement proper authorization checks
2. **Input Validation**: Comprehensive parameter validation prevents invalid operations
3. **Payment Security**: STX transfers are atomic and use built-in transfer functions
4. **State Consistency**: All state changes are validated before execution
5. **Overflow Protection**: Arithmetic operations are safe from overflow attacks

## Deployment Requirements

- **Blockchain**: Stacks blockchain
- **Language**: Clarity smart contract language
- **Dependencies**: None (uses only built-in Clarity functions)
- **Minimum STX**: Project owners must have sufficient STX to cover task payments

## Configuration

### Constants
- `MAX-TEAM-SIZE`: 20 members per project
- `MIN-RATING-SCORE`: 1 (minimum rating)
- `MAX-RATING-SCORE`: 5 (maximum rating)
- `ACTIVE-PROJECT-STATUS`: "active"
- `PENDING-TASK-STATUS`: "pending"
- `COMPLETED-TASK-STATUS`: "completed"

## Development and Testing

### Prerequisites
- Clarinet CLI for local development
- Stacks blockchain testnet access
- STX tokens for testing

### Testing Scenarios
1. Project creation and management
2. Team member addition and removal
3. Task creation, assignment, and completion
4. Payment processing and verification
5. Performance tracking and rating system
6. Access control and authorization
7. Error handling and edge cases