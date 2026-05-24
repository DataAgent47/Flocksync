# Flocksync

![Flocksync logo](https://github.com/DataAgent47/Flocksync/blob/main/frontend/assets/images/logo-bird.png?raw=true)

<p align="center">
	[ <a href="https://dataagent47.github.io/Flocksync/">Live Demo</a> |
	<a href="frontend/README.md#installation">Installation</a> |
	<a href="https://www.figma.com/design/nzkiU2O97eiKWmJX4Uz2iI/Rental-project?node-id=163-1090&t=1CeewaEjvDEJbp7v-1">Figma Designs</a> ]
</p>

Flocksync connects tenants and rental managers to make communication and operations easier.  

This app aims to centralize announcements, maintenance requests/bookings, and neighborhood communications, so building residents can report issues, share important events, and receive timely updates. Designed for tenants and management alike, Flocksync improves transparency and responsiveness between both parties while supporting the greater community.

## Features

- Intuitive dashboard with announcements and quick actions
- Building user management, with verification and messaging options
- Building-wide and Neighborhood-wide Forums for interacting with other users
- Cross-platform Flutter app (Android / iOS / Web)
- Node.js backend for API handling
- OpenStreetMaps for address parsing/verification and Nominatim for rendering
- Supabase for saving images and documents

## Architecture

- Frontend: `frontend/` — Flutter application and web manifest
- Backend: `flocksync-backend/` — Node.js server for APIs

## Installation

- [Frontend instructions](frontend/README.md#installation)

Most of the app can be used with just the Flutter frontend. However, the backend will be needed for some features, including user account creation.

- [Backend instructions](flocksync-backend/README.md)

## Contact

For questions or feedback, please feel free to reach out!

- Create an issue: [Open an issue](https://github.com/DataAgent47/Flocksync/issues)
- Submit a pull request: [Open a pull request](https://github.com/DataAgent47/Flocksync/pulls)