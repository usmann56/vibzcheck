┌──────────────────────────┐
│        Flutter App       │
│  (Home, Search, Player,  │
│   Voting, MessageBoard)  │
└───────────┬──────────────┘
            │
            │ HTTPS
            ▼
┌──────────────────────────┐
│      Firebase Backend    │
│                          │
│  ┌────────────────────┐ │
│  │   Firestore DB     │ │
│  │                    │ │
│  │  • users           │ │
│  │  • playlists       │ │
│  │  • messages        │ │
│  └────────────────────┘ │
│                          │
│  ┌────────────────────┐ │
│  │ Firebase Auth      │ │
│  │  • login/register  │ │
│  │  • re-auth         │ │
│  └────────────────────┘ │
└───────────┬──────────────┘



┌──────────────────────────┐
│        Flutter App       │
│  (Home, Search, Player,  │
│   Voting, MessageBoard)  │
└───────────┬──────────────┘
            │
            │ External APIs
            ▼
┌──────────────────────────┐
│        Spotify API       │
│                          │
│  • Track Search          │
│  • Audio Features        │
│    (valence, energy)     │
└───────────┬──────────────┘
            
            
┌──────────────────────────┐
│        Flutter App       │
│  (Home, Search, Player,  │
│   Voting, MessageBoard)  │
└───────────┬──────────────┘
            │
            │ HTTPS
            ▼
            │
┌──────────────────────────┐
│         Deezer API       │
│                          │
│  • Search Track          │
│  • Preview MP3 URL       │
│    (expiring links)      │
└──────────────────────────┘
