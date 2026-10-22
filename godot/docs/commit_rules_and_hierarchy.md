Rules for commiting in this project:

1 - BRANCHES HIERARCHY:

    main (A)                                   
    |
    └── develop (B)
            |
            ├──feature/NAME_OF_FEATURE_01 (C)
            |
            ├──feature/NAME_OF_FEATURE_02
            .
            .
            .
            └──feature/NAME_OF_FEATURE_n


This sections explains branches hierarchy and commits conventions used in this project.

    A - main: production branch, this will contain stable builds and only commits from develop will be merged into it.

    Stable build commits will be identified by the following structure (for eg):
        
        Stable Build [V_1.00]: (brief description of the build's state respect from previous version)

    
    B - develop: main experimental branch which every feature will be merge into. Before a work-session, every contributor must pull changes from this branch to ensure a workflow with the lates changes, avoiding future merging-conflicts. At stable-build-archievement (and/or certain milestone) merging with main will be allowed (develop -> main)
    
    Commits in this branch should briefly summarize a description for brand new features implementation (for eg):
        
        Combat System: Add basic interaction between health and atack registers. Changes can be found in: /systems/combat

    C - feature/NAME_OF_FEATURE: experimental branch which contains a specific set of changes or implementations, developed by a contributor. At milestone archievement, merging with develop will be allowed (feature/NAME_OF_FEATURE -> develop). There will be no commit-convention required for this branches, apart from the merging with develop commit, which should have a summarize description of the feature itself (see develop branch for more info).


