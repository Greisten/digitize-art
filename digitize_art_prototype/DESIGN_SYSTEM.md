# Design System - Digitize.art Mobile App

## Overview

This design system matches the digitize.art website aesthetic, providing a cohesive brand experience across web and mobile platforms.

## Color Palette

### Primary Colors (Dark Brown)
- **Main**: `#33271E` - Primary brand color
- **Light**: `#534031` - Hover states, secondary elements
- **Dark**: `#130E0B` - Shadows, deep backgrounds

### Secondary Colors (Purple)
- **Main**: `#8640AE` - Call-to-action buttons, highlights
- **Light**: `#9E5DC4` - Active states, emphasis
- **Dark**: `#693289` - Pressed states

### Accent Colors (Cream/Beige)
- **Main**: `#F5F5F0` - Backgrounds, cards
- **Light**: `#FFFFFF` - Pure white for contrast
- **Dark**: `#E1E1D1` - Borders, subtle divisions

### Functional Colors
- **Success**: `#26A94C` - Confirmation, success states
- **Error**: `#ED262D` - Errors, destructive actions
- **Warning**: `#FFA726` - Warnings, caution states

## Typography

### Fonts
- **Headings**: Space Grotesk (via Google Fonts)
  - Bold, geometric, modern
  - Used for titles, buttons, navigation
  
- **Body Text**: Inter (via Google Fonts)
  - Clean, readable, professional
  - Used for paragraphs, descriptions, labels

### Text Sizes
- Display Large: 57px
- Display Medium: 45px
- Display Small: 36px
- Headline Large: 32px
- Headline Medium: 28px
- Headline Small: 24px
- Title Large: 22px
- Title Medium: 16px
- Title Small: 14px
- Body Large: 16px
- Body Medium: 14px
- Body Small: 12px

## Components

### Buttons
- **Border Radius**: 12px (rounded corners)
- **Padding**: 32px horizontal, 16px vertical
- **Primary Button**: Purple background (#8640AE), white text
- **Secondary Button**: Outlined with purple border
- **Height**: 56px for main CTAs

### Cards
- **Border Radius**: 12px
- **Elevation**: 2 (subtle shadow)
- **Background**: Cream (#F5F5F0) on light theme, Dark brown on dark theme
- **Padding**: 16-24px depending on content

### Input Fields
- **Border Radius**: 12px
- **Border Color**: Light brown (#534031)
- **Focus Color**: Purple (#8640AE)
- **Padding**: 16px all sides

### Icons
- Material Design icons
- Size: 24px default, 32px for emphasis, 100px for hero elements
- Color: Context-dependent (white on dark backgrounds, dark on light backgrounds)

## Responsive Layout

### Breakpoints
- Mobile: < 600px
- Tablet: 600px - 1024px
- Desktop: > 1024px

### Spacing System
- 4px base unit
- Common spacings: 8, 12, 16, 24, 32, 40, 60px
- Consistent margins and paddings throughout

### Grid
- Mobile: Single column with 16-32px padding
- Tablet: 2 columns where appropriate
- Desktop: Up to 3-4 columns for galleries

## Animations

### Durations
- Fast: 200ms (hover states, small interactions)
- Medium: 400ms (page transitions, cards)
- Slow: 800ms (splash screen, onboarding)

### Curves
- **easeIn**: Fade in effects
- **easeOut**: Slide animations
- **easeInOut**: Smooth transitions

### Effects
- Fade animations for screens
- Slide animations for page views
- Scale animations for buttons/cards on press
- Hero animations for logo continuity

## Accessibility

### Contrast
- Text on light backgrounds: Dark brown (#4A3728) or darker
- Text on dark backgrounds: White (#FFFFFF) or light cream (#F3F4F6)
- Minimum contrast ratio: 4.5:1 for normal text, 3:1 for large text

### Touch Targets
- Minimum size: 44x44px (iOS standard)
- Preferred size: 56x56px for primary actions
- Adequate spacing between interactive elements

### Screen Reader Support
- Semantic labels for all interactive elements
- Proper heading hierarchy
- Alt text for images and icons

## Dark Mode

### Colors (Dark Theme)
- Background: Primary Dark (#130E0B)
- Surface: Primary Main (#33271E)
- Text: Light cream (#F3F4F6)
- Secondary text: Gray (#9CA3AF)

### Contrast Adjustments
- Elevated surfaces use lighter shades
- Borders become more subtle
- Shadows use darker colors

## Usage Guidelines

### Do's ✅
- Use Space Grotesk for all headings and buttons
- Maintain consistent spacing using the 4px base unit
- Use purple for call-to-action elements
- Ensure sufficient contrast for text readability
- Apply smooth animations for better UX

### Don'ts ❌
- Don't mix multiple font families
- Don't use colors outside the defined palette
- Don't create buttons smaller than 44x44px
- Don't use harsh animations (keep them smooth)
- Don't ignore accessibility guidelines

## Implementation

### Flutter Theme
All design tokens are implemented in `lib/theme/app_theme.dart`:
- Color constants
- TextTheme with Google Fonts
- Button themes
- Card themes
- Input decoration themes

### Localization
Multi-language support in `lib/l10n/app_localizations.dart`:
- English (default)
- French
- Spanish
- German
- Italian

## Resources

- **Website**: [digitize.art](https://digitize.art)
- **Fonts**: [Google Fonts](https://fonts.google.com)
- **Icons**: [Material Icons](https://fonts.google.com/icons)
- **Design Reference**: digitize.art website color scheme and typography
