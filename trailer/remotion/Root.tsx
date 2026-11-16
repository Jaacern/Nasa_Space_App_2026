import React from "react";
import { Composition } from "remotion";
import { AresTrailer, FPS, TOTAL } from "./Trailer";

export const AresRoot: React.FC = () => (
  <Composition id="AresTrailer" component={AresTrailer} durationInFrames={TOTAL} fps={FPS} width={1920} height={1080} />
);
