#!/bin/bash
# Select the Nerd Font from https://www.nerdfonts.com/font-downloads
# Script improvements: Enhanced error handling, readability, and structure

echo "[-] Download The Nerd fonts [-]"
echo "##############################"
echo "Select a Nerd Font from the list below:"

# Array of available fonts
fonts_list=("Agave" "AnonymousPro" "Arimo" "AurulentSansMono" "BigBlueTerminal" "BitstreamVeraSansMono" "CascadiaCode" "CodeNewRoman" "ComicShannsMono" "Cousine" "DaddyTimeMono" "DejaVuSansMono" "FantasqueSansMono" "FiraCode" "FiraMono" "Gohu" "Go-Mono" "Hack" "Hasklig" "HeavyData" "Hermit" "iA-Writer" "IBMPlexMono" "InconsolataGo" "InconsolataLGC" "Inconsolata" "IosevkaTerm" "JetBrainsMono" "Lekton" "LiberationMono" "Lilex" "Meslo" "Monofur" "Monoid" "Mononoki" "MPlus" "NerdFontsSymbolsOnly" "Noto" "OpenDyslexic" "Overpass" "ProFont" "ProggyClean" "RobotoMono" "ShareTechMono" "SourceCodePro" "SpaceMono" "Terminus" "Tinos" "UbuntuMono" "Ubuntu" "VictorMono")

# Prompt for font selection
PS3="Enter a number to select a font: "
select font_name in "${fonts_list[@]}" "Quit"; do
    if [ "$font_name" = "Quit" ]; then
        echo "Exiting the script."
        break
    elif [ -n "$font_name" ]; then
        echo "Starting download for $font_name Nerd Font..."

        # Define the download URL
        font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip"

        # Check if curl or wget is available
        if command -v curl > /dev/null; then
            downloader="curl -OL"
        elif command -v wget > /dev/null; then
            downloader="wget"
        else
            echo "Error: Neither curl nor wget is installed. Please install one of them to proceed."
            break
        fi

        # Ensure the .fonts directory exists
        fonts_dir="$HOME/.fonts"
        mkdir -p "$fonts_dir"

        echo "Downloading font from: $font_url"

        # Download the font
        $downloader "$font_url" || { echo "Error downloading $font_name. Please check the URL."; break; }

        # Unzip the downloaded font
        echo "Unzipping the font..."
        unzip -q "$font_name.zip" -d "$fonts_dir/$font_name" || { echo "Error unzipping the font."; break; }

        # Update font cache
        echo "Updating font cache..."
        fc-cache -fv

        echo "Font $font_name installed successfully!"
        break
    else
        echo "Invalid selection. Please choose a valid number from the list."
        continue
    fi
done
