# Layover

A SwiftUI-based iOS travel app that helps users discover places, manage itineraries, and save favorite locations during their travels.

## Overview

Layover is a comprehensive travel companion app designed to streamline travel planning and exploration. It combines place discovery, itinerary management, mapping, and user authentication to provide a seamless travel experience.

## Features

- **Explore** - Discover places and attractions near you with detailed information
- **Place Details** - View comprehensive details, reviews, and ratings for locations
- **Itinerary Management** - Create and manage travel itineraries
- **Map View** - Visualize locations on an interactive map
- **Favorites** - Save and manage your favorite places
- **Reviews** - Read and share reviews about places
- **User Profiles** - Manage your account and preferences
- **Authentication** - Secure user login and account management

## Project Structure

```
Layover/
├── App/
│   ├── LayoverApp.swift          # Main app entry point
│   └── RootTabView.swift         # Tab navigation controller
├── Features/                      # Feature modules
│   ├── Explore/                   # Place discovery
│   ├── Map/                       # Map visualization
│   ├── PlaceDetail/               # Place information
│   ├── Itinerary/                 # Itinerary management
│   ├── Saved/                     # Saved places
│   ├── Profile/                   # User profile
│   ├── Results/                   # Search results
│   └── Onboarding/                # Onboarding flow
├── Core/
│   ├── Models/                    # Data models
│   ├── Services/                  # Business logic and API integration
│   ├── Database/                  # Local database schema
│   ├── Theme/                     # App theming
│   └── Utils/                     # Utilities and extensions
└── Assets.xcassets/               # App resources

```

## Architecture

The app follows a modular architecture with clear separation of concerns:

- **Models** - Data structures for places, itineraries, reviews, and travel results
- **Services** - Business logic including authentication, favorites, itinerary, places, reviews, routes, and database management
- **Views** - SwiftUI feature views organized by feature module
- **ViewModels** - State management using `@StateObject` and Combine

## Key Services

- **AuthViewModel** - Authentication and user session management
- **FavoritesService** - Manage saved places
- **ItineraryService** - Create and manage travel itineraries
- **PlacesService** - Fetch and manage place data
- **ReviewsService** - Handle place reviews
- **RoutesService** - Calculate routes between locations
- **SupabaseManager** - Backend database integration

## Technology Stack

- **Swift** - Programming language
- **SwiftUI** - UI framework
- **Combine** - Reactive programming
- **Supabase** - Backend and database
- **MapKit** - Map visualization

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Setup

1. Clone the repository
2. Open `Layover.xcodeproj` in Xcode
3. Configure Supabase credentials in `SupabaseManager`
4. Build and run the app

## Development

The app uses a tab-based navigation architecture with the following main tabs:
- Explore - Discovery interface
- Map - Location visualization
- Itinerary - Trip planning
- Saved - Favorite places
- Profile - User account

## Database

The app uses Supabase for backend storage with a local SQLite schema defined in `Core/Database/schema.sql`.

## License

Copyright © 2026. All rights reserved.
