'use client';

import { useNavigate } from "react-router";
import Spline from "@splinetool/react-spline";

export default function Splash(): JSX.Element {
  const navigate = useNavigate();

  return (
    <div className="relative w-full h-screen overflow-hidden bg-black">

      {/* 🌌 Spline Background */}
      <Spline
        scene="https://prod.spline.design/xoa36hbmhTAarN-U/scene.splinecode"
        className="absolute top-0 left-0 w-full h-full"
      />

      {/* 🧊 Overlay Content */}
      <div className="absolute top-0 left-0 z-10 flex min-h-screen w-full items-center justify-center px-6">
        <div className="max-w-3xl text-center">

          <h1 className="mb-6 text-7xl md:text-8xl font-bold tracking-tight text-white">
            Outloop AI
          </h1>

          <p className="mb-16 text-xl md:text-2xl font-light text-white/80">
            Build your startup on Autopilot.
          </p>

          <button
            onClick={() => navigate("/trends/loading")}
            className="backdrop-blur-xl bg-white/10 border border-white/20 rounded-full px-12 py-5 text-lg font-semibold text-white transition-all hover:bg-white/20 hover:scale-105 active:scale-95"
          >
            Get Started
          </button>

        </div>
      </div>

    </div>
  );
}