(function () {
  'use strict';

  function formatTime(value) {
    if (!Number.isFinite(value) || value < 0) return '00:00';
    var minutes = Math.floor(value / 60);
    var seconds = Math.floor(value % 60);
    return String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
  }

  function setRangeProgress(input) {
    var min = Number(input.min) || 0;
    var max = Number(input.max) || 1;
    var value = Number(input.value) || 0;
    var progress = max > min ? ((value - min) / (max - min)) * 100 : 0;
    input.style.setProperty('--elma-range-progress', progress + '%');
  }

  function initPlayer(root) {
    var player = root.querySelector('[data-elma-player]');
    var video = root.querySelector('video');
    var playButton = root.querySelector('[data-elma-play]');
    var overlayButton = root.querySelector('[data-elma-play-overlay]');
    var seek = root.querySelector('[data-elma-seek]');
    var time = root.querySelector('[data-elma-time]');
    var muteButton = root.querySelector('[data-elma-mute]');
    var volume = root.querySelector('[data-elma-volume]');
    var fullscreenButton = root.querySelector('[data-elma-fullscreen]');

    if (!player || !video || !playButton || !seek || !time || !muteButton || !volume || !fullscreenButton) return;

    var fallbackDuration = Number(seek.max) || 74;

    function duration() {
      return Number.isFinite(video.duration) && video.duration > 0 ? video.duration : fallbackDuration;
    }

    function updateTimeline() {
      var total = duration();
      seek.max = String(total);
      seek.value = String(Math.min(video.currentTime || 0, total));
      time.value = formatTime(video.currentTime || 0) + ' / ' + formatTime(total);
      time.textContent = time.value;
      setRangeProgress(seek);
    }

    function updatePlayState() {
      var isPlaying = !video.paused && !video.ended;
      playButton.textContent = isPlaying ? 'PAUSE' : video.ended ? 'REPLAY' : 'PLAY';
      playButton.setAttribute('aria-label', isPlaying ? 'Pause ELMA project film' : 'Play ELMA project film');
      playButton.setAttribute('aria-pressed', String(isPlaying));
      if (isPlaying || video.currentTime > 0) player.classList.add('is-started');
    }

    function updateSoundState() {
      var isMuted = video.muted || video.volume === 0;
      muteButton.textContent = isMuted ? 'SOUND OFF' : 'SOUND ON';
      muteButton.setAttribute('aria-label', isMuted ? 'Unmute ELMA project film' : 'Mute ELMA project film');
      muteButton.setAttribute('aria-pressed', String(isMuted));
      volume.value = String(video.volume);
      setRangeProgress(volume);
    }

    function playVideo() {
      if (video.ended) video.currentTime = 0;
      var playPromise = video.play();
      if (playPromise && typeof playPromise.catch === 'function') {
        playPromise.catch(function () {
          updatePlayState();
        });
      }
    }

    function togglePlayback() {
      if (video.paused || video.ended) playVideo();
      else video.pause();
    }

    function toggleMute() {
      if (video.muted || video.volume === 0) {
        video.muted = false;
        if (video.volume === 0) video.volume = 1;
      } else {
        video.muted = true;
      }
      updateSoundState();
    }

    function toggleFullscreen() {
      var fullscreenElement = document.fullscreenElement || document.webkitFullscreenElement;
      if (fullscreenElement) {
        var exit = document.exitFullscreen || document.webkitExitFullscreen;
        if (exit) exit.call(document);
        return;
      }

      var request = player.requestFullscreen || player.webkitRequestFullscreen;
      if (request) {
        request.call(player);
      } else if (video.webkitEnterFullscreen) {
        video.webkitEnterFullscreen();
      }
    }

    playButton.addEventListener('click', togglePlayback);
    if (overlayButton) overlayButton.addEventListener('click', togglePlayback);
    video.addEventListener('click', togglePlayback);
    muteButton.addEventListener('click', toggleMute);
    fullscreenButton.addEventListener('click', toggleFullscreen);

    seek.addEventListener('input', function () {
      video.currentTime = Number(seek.value);
      updateTimeline();
    });

    volume.addEventListener('input', function () {
      video.volume = Number(volume.value);
      video.muted = video.volume === 0;
      updateSoundState();
    });

    video.addEventListener('loadedmetadata', updateTimeline);
    video.addEventListener('durationchange', updateTimeline);
    video.addEventListener('timeupdate', updateTimeline);
    video.addEventListener('play', updatePlayState);
    video.addEventListener('pause', updatePlayState);
    video.addEventListener('ended', updatePlayState);
    video.addEventListener('volumechange', updateSoundState);

    video.addEventListener('keydown', function (event) {
      var key = event.key.toLowerCase();
      if (key === ' ' || key === 'k') {
        event.preventDefault();
        togglePlayback();
      } else if (key === 'arrowleft') {
        event.preventDefault();
        video.currentTime = Math.max(0, video.currentTime - 5);
      } else if (key === 'arrowright') {
        event.preventDefault();
        video.currentTime = Math.min(duration(), video.currentTime + 5);
      } else if (key === 'm') {
        event.preventDefault();
        toggleMute();
      } else if (key === 'f') {
        event.preventDefault();
        toggleFullscreen();
      }
    });

    function updateFullscreenState() {
      var isFullscreen = (document.fullscreenElement || document.webkitFullscreenElement) === player;
      fullscreenButton.textContent = isFullscreen ? 'EXIT FULLSCREEN' : 'FULLSCREEN';
      fullscreenButton.setAttribute('aria-label', isFullscreen ? 'Exit ELMA project film fullscreen' : 'Show ELMA project film fullscreen');
    }

    document.addEventListener('fullscreenchange', updateFullscreenState);
    document.addEventListener('webkitfullscreenchange', updateFullscreenState);

    updateTimeline();
    updatePlayState();
    updateSoundState();
  }

  function init() {
    document.querySelectorAll('[data-elma-video]').forEach(initPlayer);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init, { once: true });
  else init();
})();
