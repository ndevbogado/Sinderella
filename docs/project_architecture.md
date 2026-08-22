project/                                      
│                                                   
├── assets/             -> Localizacion de archivos de arte (concepts y finales), musica, sonido y material licenciado                                                                                                                                                                                     
│                                                   
├── game/                                           
│   ├── data/           -> Datos fijos del juego accesibles a traves de archivos .csv
│   │   ├── items/                                  
│   │   ├── enemies/                                
│   │   ├── skills/                                 
│   │   ├── quests/                                 
│   │   ├── dialogue/                               
│   │   └── classes/                                
│   │                                               
│   ├── maps/                                       
│   ├── characters/                                 
│   └── cinematics/
│                                                   
├── systems/            -> Funcionalidades del juego y manejo de datos mutables                           
│   ├── combat/                                     
│   ├── inventory/                                  
│   ├── save/                                       
│   ├── dialogue/                                   
│   ├── ai/                                         
│   └── ui/                                         
│                                                   
├── tools/              -> Herramientas y gestores de desarrollo internas            
├── docs/               -> Documentacion general de como funciona cada componente    
└── tests/              -> Seccion para el testeo de codigo    



# Basic player or npc dir structure:

project/
└── game/
    └── characters/
        ├─── player/
        │    ├── Player.tscn
        │    ├── Player.gd
        │    ├── PlayerAnimations.tres
        │    │
        │    └── sprites/
        │        ├── idle/
        │        │   ├── idle_0.png
        │        │   └── idle_1.png
        │        │
        │        ├── walk/
        │        │   ├── walk_0.png
        │        │   └── walk_1.png
        │        │
        │        └── attack/
        │            ├── attack_0.png
        │            └── attack_1.png 
        └── npc_01/ 
            ├── Npc_01.tscn
            ├── Npc_01.gd
            ├── Npc_01Animations.tres
            │       
            └── sprites/
                ├── idle/
                │   ├── idle_0.png
                │   └── idle_1.png
                │   
                ├── walk/
                │   ├── walk_0.png
                │   └── walk_1.png
                │   
                └── attack/
                    ├── attack_0.png
                     └── attack_1.png  
