/* ----------------------------------------------------
   🪐 MINIMALIST ORBITAL SOLAR SYSTEM CONSOLE
   Author: Custom Hive Release
   Platform: Übersicht Engine (macOS Desktop Layer)

   Safe for public sharing. This code relies entirely on
   hardware-accelerated styling and contains no personal metrics.
   ---------------------------------------------------- */

// 1. Static refresh frequency to let the GPU manage fluid movement seamlessly
export const refreshFrequency = 1000000;

export const className = `
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, calc(-50% + 280px));
  pointer-events: none !important;
  z-index: 1;

  .solar-system {
    position: relative;
    width: 600px;
    height: 600px;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  /* ☀️ THE SUN: Glowing yellow-orange core star */
  .sun {
    position: absolute;
    width: 30px;
    height: 30px;
    background: radial-gradient(circle at 35% 35%, #fffb00 0%, #ff7700 60%, #ff0000 100%);
    border-radius: 50%;
    box-shadow: 0 0 20px rgba(255, 115, 0, 0.8),
                0 0 40px rgba(255, 60, 0, 0.4);
    z-index: 10;
  }

  /* Universal circular orbital tracks */
  .orbit-track {
    position: absolute;
    border: 1px dashed rgba(255, 115, 0, 0.12);
    border-radius: 50%;
  }

  /* Universal planet particle styles */
  .planet {
    position: absolute;
    top: 0;
    left: 50%;
    transform: translateX(-50%);
    border-radius: 50%;
    background: #ffffff;
    box-shadow: 0 0 8px rgba(255, 255, 255, 0.8);
  }

  /* ----------------------------------------------------
     ORBITAL TIMINGS: Proportional to true planetary velocities.
     ---------------------------------------------------- */

  /* MERCURY */
  .orbit-mercury {
    width: 80px; height: 80px;
    animation: orbit-spin 2.4s linear infinite;
  }
  .planet-mercury { width: 4px; height: 4px; background: rgba(255, 187, 0, 0.7); }

  /* VENUS */
  .orbit-venus {
    width: 130px; height: 130px;
    animation: orbit-spin 6.2s linear infinite;
  }
  .planet-venus { width: 6px; height: 6px; background: rgba(255, 115, 0, 0.8); }

  /* EARTH (10-second reference baseline = 1 Year) */
  .orbit-earth {
    width: 190px; height: 190px;
    animation: orbit-spin 10s linear infinite;
  }
  .planet-earth { width: 7px; height: 7px; background: #ffffff; box-shadow: 0 0 10px #4169E1; }

  /* MARS */
  .orbit-mars {
    width: 250px; height: 250px;
    animation: orbit-spin 18.8s linear infinite;
  }
  .planet-mars { width: 5px; height: 5px; background: rgba(255, 59, 48, 0.8); }

  /* JUPITER */
  .orbit-jupiter {
    width: 360px; height: 360px;
    animation: orbit-spin 118.6s linear infinite;
  }
  .planet-jupiter { width: 14px; height: 14px; background: rgba(235, 180, 110, 0.6); border: 1px solid #ffaa00; }

  /* SATURN */
  .orbit-saturn {
    width: 470px; height: 470px;
    animation: orbit-spin 294.6s linear infinite;
  }
  .planet-saturn { width: 11px; height: 11px; background: #ffffff; border: 2px solid rgba(255, 174, 0, 0.5); }

  /* URANUS */
  .orbit-uranus {
    width: 540px; height: 540px;
    animation: orbit-spin 840.1s linear infinite;
  }
  .planet-uranus { width: 8px; height: 8px; background: rgba(0, 255, 255, 0.4); }

  /* Mathematical spinning execution engine */
  @keyframes orbit-spin {
    0%   { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
`;

export const render = () => {
  return (
    <div className="solar-system">
      <div className="sun"></div>
      <div className="orbit-track orbit-mercury"><div className="planet planet-mercury"></div></div>
      <div className="orbit-track orbit-venus"><div className="planet planet-venus"></div></div>
      <div className="orbit-track orbit-earth"><div className="planet planet-earth"></div></div>
      <div className="orbit-track orbit-mars"><div className="planet planet-mars"></div></div>
      <div className="orbit-track orbit-jupiter"><div className="planet planet-jupiter"></div></div>
      <div className="orbit-track orbit-saturn"><div className="planet planet-saturn"></div></div>
      <div className="orbit-track orbit-uranus"><div className="planet planet-uranus"></div></div>
    </div>
  );
};
