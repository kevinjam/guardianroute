import { GoogleGenerativeAI } from "@google/generative-ai";
import {
  HazardAnalysis,
  hazardAnalysisSchema,
  parseHazardAnalysis,
} from "./hazardAnalysisSchema";

const MODEL = "gemini-2.0-flash";

export async function analyzeHazardMedia(input: {
  imageBase64: string;
  imageMimeType: string;
  audioBase64?: string;
  audioMimeType?: string;
  transcript?: string;
  latitude: number;
  longitude: number;
  heading?: number;
  speed?: number;
}): Promise<HazardAnalysis> {
  const rawKey = (process.env.GEMINI_API_KEY ?? "").trim();
  const apiKey = !rawKey || rawKey.startsWith("PASTE_YOUR_") || rawKey.startsWith("YOUR_") ? "" : rawKey;
  if (!apiKey) {
    return fallbackAnalysis(input.transcript);
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: MODEL,
    generationConfig: {
      responseMimeType: "application/json",
    },
  });

  const context = [
    "You are GuardianRoute road-safety AI for Uganda (boda boda riders, Kampala roads).",
    "Analyze the hazard from the photo and rider notes.",
    `GPS: ${input.latitude}, ${input.longitude}.`,
    input.heading != null ? `Heading: ${input.heading}°.` : "",
    input.speed != null ? `Speed: ${input.speed} m/s.` : "",
    input.transcript ? `Rider said: ${input.transcript}` : "",
    "Respond with JSON only: hazardType, severity, confidence, description, recommendedAction.",
    "hazardType must be one of POTHOLE, ROAD_DAMAGE, FLOODING, ROAD_OBSTRUCTION, ACCIDENT, DANGEROUS_INTERSECTION, CONSTRUCTION, OTHER.",
    "severity must be LOW, MODERATE, HIGH, or CRITICAL.",
    "confidence is 0.0 to 1.0.",
  ]
    .filter(Boolean)
    .join("\n");

  const parts: Array<{ text: string } | { inlineData: { mimeType: string; data: string } }> = [
    { text: context },
    {
      inlineData: {
        mimeType: input.imageMimeType,
        data: input.imageBase64,
      },
    },
  ];

  if (input.audioBase64 && input.audioMimeType) {
    parts.push({
      inlineData: {
        mimeType: input.audioMimeType,
        data: input.audioBase64,
      },
    });
  }

  const result = await model.generateContent(parts);

  const text = result.response.text();
  try {
    return parseHazardAnalysis(text);
  } catch {
    return fallbackAnalysis(input.transcript);
  }
}

function fallbackAnalysis(transcript?: string): HazardAnalysis {
  return hazardAnalysisSchema.parse({
    hazardType: "OTHER",
    severity: "MODERATE",
    confidence: 0.55,
    description:
      transcript?.trim() ||
      "Road hazard reported. Automated analysis unavailable.",
    recommendedAction: "Reduce speed and proceed with caution.",
  });
}
