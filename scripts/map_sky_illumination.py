#!/usr/bin/env python3
"""Regenerate sky brightness data and its review chart (Pillow, matplotlib)."""
import hashlib
import json
import os
from pathlib import Path

from PIL import Image, ImageStat

ROOT = Path(__file__).resolve().parents[1]
SAMPLE_COUNT = 128
PROFILES = {}
METADATA = {}
for phase in ('day', 'night'):
    path = ROOT / 'Resources' / f'sky-{phase}.png'
    with Image.open(path) as source:
        image = source.convert('RGB')
        width, height = image.size
        # Mean encoded RGB, normalized to 0...1. This is an artwork control
        # signal, not a measurement of physical illumination.
        PROFILES[phase] = [
            sum(ImageStat.Stat(image.crop((
                i * width // SAMPLE_COUNT, 0,
                (i + 1) * width // SAMPLE_COUNT, height
            ))).mean) / 765
            for i in range(SAMPLE_COUNT)
        ]
        METADATA[phase] = {
            'file': path.name, 'width': width, 'height': height,
            'mean_brightness': sum(ImageStat.Stat(image).mean) / 765,
            'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        }

payload = {
    'method': 'Mean sRGB channel value per full-height horizontal bin; 0...1.',
    'images': METADATA, **PROFILES,
}
output = ROOT / 'Resources' / 'sky-illumination.json'
output.write_text(json.dumps(payload, indent=2) + '\n')

def brightness(position, visible_fraction):
    total = 0
    for i in range(32):
        p = (position + ((i + 0.5) / 32 - 0.5) * visible_fraction) % 1
        profile = PROFILES['day' if p < 0.5 else 'night']
        u = p * 2 if p < 0.5 else (p - 0.5) * 2
        index = max(0, min(len(profile) - 1, u * len(profile) - 0.5))
        low = int(index)
        total += profile[low] + (profile[min(low + 1, len(profile) - 1)] - profile[low]) * (index - low)
    return total / 32

def opacity(position, visible_fraction):
    p = position % 1
    if p >= 0.5:
        return 1
    center = brightness(0.25, visible_fraction)
    edge = brightness(0 if p < 0.25 else 0.5, visible_fraction)
    contrast = center - edge
    t = ((center - brightness(p, visible_fraction)) / contrast
         if contrast > 0.000001 else abs(p * 2 - 0.5) * 2)
    t = max(0, min(1, t))
    return t * t * (3 - 2 * t)

# Representative 390 x 844 portrait viewport, aspect-filled skies.
visible_fraction = 390 / (2 * 844 * METADATA['day']['width'] / METADATA['day']['height'])
os.environ.setdefault('MPLCONFIGDIR', '/tmp/stick-illumination-matplotlib')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
matplotlib.rcParams['svg.hashsalt'] = 'stick-sky-illumination'

timeline = [i / 512 for i in range(513)]
positions = [(0.25 + t) % 1 for t in timeline]
figure, axes = plt.subplots(2, 1, figsize=(10, 5.5), sharex=True, constrained_layout=True)
axes[0].plot(timeline, [brightness(p, visible_fraction) for p in positions], color='#527dab')
axes[0].set(ylabel='Average RGB (0–1)', title='Visible sky brightness and landscape shadow')
axes[1].plot(timeline, [opacity(p, visible_fraction) for p in positions], color='#3b4651')
axes[1].set(ylabel='Shadow opacity', xlabel='Full day/night circuit', ylim=(-0.03, 1.03))
for axis in axes:
    axis.axvspan(0.25, 0.75, color='#566a94', alpha=0.12)
    axis.grid(alpha=0.2)
    axis.set_xticks([0, 0.25, 0.5, 0.75, 1], ['Day center', 'Night starts', 'Night center', 'Day starts', 'Day center'])
chart = ROOT / 'docs' / 'sky-illumination.svg'
chart.parent.mkdir(exist_ok=True)
figure.savefig(chart, metadata={'Date': None})
chart.write_text('\n'.join(line.rstrip() for line in chart.read_text().splitlines()) + '\n')
figure.savefig('/tmp/stick-sky-illumination.png', dpi=150)
plt.close(figure)
print(json.dumps({'images': METADATA, 'samples_per_image': SAMPLE_COUNT,
                  'data': str(output), 'chart': str(chart)}, indent=2))
