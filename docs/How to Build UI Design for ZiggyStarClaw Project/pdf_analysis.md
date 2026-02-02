# ZiggyStarClaw UI Visual Guide Analysis

## Overview
- **Application Type**: Workspace-first AI worker UI for OpenClaw desktop nodes
- **Core Concepts**: Projects + Sources + Artifacts + Runs + Approvals + Agents
- **Theme**: Light Mode (clean, modern design)

## UI Components Identified

### 1. Projects Overview (Page 1)
- **Left Sidebar**: Project list with icons
  - "My Projects" header
  - Project items (Project Alpha, Project Beta) with folder icons
  - Active indicator badge
  - "+ New Project" button
- **Main Content Area**: 
  - "Welcome Back!" greeting
  - Active project card with gradient background (blue sky/clouds)
  - Category cards (Marketing Analysis, Design Concepts)
  - Recent Artifacts list with file type icons and status
- **Header Bar**: App title "ZiggyStarClaw", search icon, notification icon
- **Window Controls**: macOS-style traffic lights (red, yellow, green)

### 2. Sources Management (Page 2)
- **Left Panel**: Source categories
  - Local Files
  - Project Beta (selected, highlighted)
  - Cloud Drives
  - Code Repos
  - "+ Add Source" button
- **Right Panel**: File browser
  - Project Files dropdown
  - File list with icons (proposal.docx, data.csv, image.png)
  - Checkmark indicators for indexed files
  - Expandable sections (Research Docs, Google Drive Team, GitHub Repo)

### 3. Artifact Workspace (Page 3)
- **Tab Bar**: Preview | Edit toggle
- **Content Area**: 
  - Report Summary document
  - Overview section with text
  - Key Insights section
  - Charts: Sales Performance (bar chart), Competitor Analysis (tabs: Sales, Dow, Proclues, Pemble)
- **Bottom Toolbar**: Action icons (copy, undo/redo, expand)
- **Responsive**: Shows tablet/phone variants

### 4. Run Inspector / Task Progress (Page 4)
- **Header**: "Task Progress" with settings icon
- **Step List**:
  - Checkmark icons for completed steps
  - Step numbers and names
  - Status badges (Complete, In Progress)
- **Current Step Details** section
- **"View Logs" button**
- **Side Panel**: Agent notifications with file references

### 5. Approvals Inbox (Page 5)
- **Header**: "Approvals Needed" with notification badge
- **Request Items**:
  - Request description text
  - Approve/Decline button pair (green/red)
- **Purpose**: Human-in-the-loop control for side effects

### 6. Mobile & Tablet Variants (Page 6)
- **Tablet**: Artifact-centric with collapsible side panels
- **Phone**: 
  - "Active Agents" list view
  - Agent status (Ready, Writing, Idle)
  - Status indicators with colors
  - Compact roster design

## Visual Design Specifications

### Color Palette (Light Mode)
- **Background**: White/Light gray (#FFFFFF, #F5F5F5)
- **Primary Accent**: Google-style colors (Blue, Red, Yellow, Green)
- **Text**: Dark gray/black
- **Active/Selected**: Blue highlight
- **Success**: Green checkmarks
- **Warning/Decline**: Red
- **Approve**: Green

### Typography
- **Headers**: Bold, larger size
- **Body**: Regular weight
- **Status Text**: Smaller, muted colors

### UI Patterns
- **Cards**: Rounded corners, subtle shadows
- **Buttons**: Rounded, solid colors
- **Icons**: Simple, flat design
- **Lists**: Clean rows with icons and status indicators
- **Tabs**: Pill-style toggle buttons

### Layout Structure
- **Desktop**: Three-column layout (sidebar, main, detail panel)
- **Tablet**: Two-column with collapsible panels
- **Phone**: Single column, stacked views

## Reusable Components Needed

1. **WindowFrame** - macOS-style window with traffic lights
2. **Sidebar** - Collapsible navigation panel
3. **ProjectCard** - Project display with gradient background
4. **FileListItem** - File row with icon, name, status
5. **TabBar** - Toggle between views (Preview/Edit)
6. **Button** - Primary, secondary, approve/decline variants
7. **ProgressStep** - Task step with status indicator
8. **ApprovalCard** - Request with approve/decline actions
9. **AgentStatusRow** - Agent name, status, indicator
10. **ChartContainer** - Wrapper for data visualizations
11. **SearchBar** - Input with search icon
12. **NotificationBadge** - Count indicator
13. **IconButton** - Circular icon buttons
14. **Dropdown** - Expandable selection menu
15. **Modal/Panel** - Overlay containers
