when defined(mixer):
  import sdl
  import sdl/mixer
  import std/options
  import std/os
  proc main() =
    echo "[Audio Example] Initializing SDL Audio..."
    var guard = sdlInit(InitFlags(InitFlag.audio))
    defer: guard.quit()

    echo "[Mixer] Opening audio device (22kHz, Stereo)..."
    openAudio()
    defer: closeMixAudio()

    echo "[Mixer] Reserving 2 channels for effects..."
    reserveChannels(2)

    echo "[Memory] Loading 'teste.wav'..."
    let somOpt = loadWav("teste.wav")
    if somOpt.isNone:
      quit("Error: 'teste.wav' not found! Place a WAV file next to the executable.")

    let meuSom = addr somOpt.get()

    echo "[Mixer] Setting volume to 50% (64/128)..."
    meuSom[].volume = 64

    echo "[Mixer] Playing sound on reserved channel 0..."
    let canal = meuSom[].play(channel = AudioChannel(0))

    echo "[DSP] Panning audio hard LEFT..."
    canal.panning = (255u8, 0u8)

    echo "[Loop] Waiting for sound to finish..."
    while canal.isPlaying():
      sleep(16)

    echo "[Success] Sound finished. RAII will clean up!"

  main()
else:
  echo "This example requires SDL_mixer. Compile with: -d:mixer"