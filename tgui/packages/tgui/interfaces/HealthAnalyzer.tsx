import { useBackend, useLocalState } from 'tgui/backend';
import { Section } from 'tgui/components';
import ScrollingChart from 'tgui/components/ScrollingChart';
import { Tooltip } from 'tgui-core/components';

import { clamp01 } from '../../common/math';
import { Window } from '../layouts';

const bodyPart =
  'M16 0c-3 0-3 3-3 4-1 0-1 1 0 2 0 2 2 3 2 4s-1 2-4 3-3 2-3 4c0 5 0 9-1 12s-2 5-3 6-1 2-3 2c-1 0-1 1 2 1-1 1-2 1-2 3 0 1 2 2 4-1s4-6 5-10c1-3 1-5 1-8 1 2 1 4 0 7s-2 5-2 8c0 4 0 9 1 13s1 3 1 6c0 2-1 4-1 6 1 3 2 5 2 8 0 4-2 4-2 5s0 1 1 1h3c1 0 1-1 1-3-1-3-1-5 0-8s0-5 0-7c0-1-1-1 0-5 0-2 1-5 1-12 0 7 1 10 1 12 1 4 0 4 0 5 0 2-1 4 0 7 1 3 1 5 0 8 0 2 0 3 1 3h3c1 0 1-1 1-1 0-1-2-1-2-5 0-3 1-5 2-8 0-2-1-4-1-6 0-3 0-2 1-6 1-3 1-9 1-13 0-3-1-5-2-8s-1-5 0-7c0 3 0 5 1 8 1 4 3 7 5 10s4 2 4 1c0-2-1-2-2-3 3 0 3-1 2-1-2 0-2-1.3333-3-2-1-1-2-3-3-6s-1-7-1-12c0-2 0-3-3-4s-4-2-4-3 2-2 2-4c1-1 1-2 0-2 0-1 0-4-3-4';

const bodyParts: BodyZoneUIPart[] = [
  {
    outline:
      'M17 10c0-1 2-2 2-4 1-1 1-2 0-2 0-1 0-4-3-4S13 3 13 4c-1 0-1 1 0 2 0 2 2 3 2 4Z',
    hitbox: 'M0 0 35 0 35 11 0 11Z',
    zoneName: 'head',
    center: { x: 16, y: 5 },
  },
  {
    outline:
      'M11 13c-3 1-3 2-3 4 0 5 0 9-1 12s-2 5-3 6-1 2-3 2c-1 0-1 1 2 1-1 1-2 1-2 3 0 1 2 2 4-1s4-6 5-10c1-3 1-5 1-8Z',
    hitbox: 'M0 11 11 11 11 22 11 28 6 42 0 42 0 22Z',
    zoneName: 'right arm',
    center: { x: 8, y: 26.5 },
  },
  {
    outline:
      'M15 10C15 11 14 12 11 13L11 23c1 2 1 4 0 7s-2 5-2 8L23 38C23 35 22 33 21 30S20 24 21 22L21 13c-3-1-4-2-4-3Z',
    hitbox: 'M11 11 21 11 21 28 24.2 37 7.8 37 11 28Z',
    zoneName: 'chest',
    center: { x: 16, y: 24 },
  },
  {
    outline:
      'M21 13c3 1 3 2 3 4 0 5 0 9 1 12s2 5 3 6 1 2 3 2c1 0 1 1-2 1 1 1 2 1 2 3 0 1-2 2-4-1s-4-6-5-10c-1-3-1-5-1-8Z',
    hitbox: 'M32 11 21 11 21 22 21 28 26 42 32 42 32 22Z',
    zoneName: 'left arm',
    center: { x: 24, y: 26.5 },
  },
  {
    outline:
      'M9 37c0 4 0 9 1 13s1 3 1 6c0 2-1 4-1 6 1 3 2 5 2 8 0 4-2 4-2 5s0 1 1 1h3c1 0 1-1 1-3-1-3-1-5 0-8s0-5 0-7c0-1-1-1 0-5 0-2 1-5 1-12L16 37Z',
    hitbox: 'M0 42 5 42 7.8 37 16 37 16 80 0 80Z',
    zoneName: 'right leg',
    center: { x: 12, y: 58.5 },
  },
  {
    outline:
      'M23 37c0 4 0 9-1 13s-1 3-1 6c0 2 1 4 1 6-1 3-2 5-2 8 0 4 2 4 2 5s0 1-1 1h-3c-1 0-1-1-1-3 1-3 1-5 0-8s0-5 0-7c0-1 1-1 0-5 0-2-1-5-1-12L16 37Z',
    hitbox: 'M16 37 24.2 37 26 42 35 42 35 80 16 80Z',
    zoneName: 'left leg',
    center: { x: 20, y: 58.5 },
  },
];

interface BodyZoneUIPart {
  outline: string;
  hitbox: string;
  zoneName: string;
  center: { x: number; y: number };
}

enum InjurySeverity {
  None = 0,
  Healing = 1,
  Active = 2,
}

interface InjuryEntry {
  name: string;
  heal_text: string;
  damage?: number | string;
  severity?: InjurySeverity;
  effectiveness_modifier?: number;
  bone_armour_modifier?: number;
  skin_armour_modifier?: number;
  pain?: number;
}

type Injuries = { [area: string]: InjuryEntry[] };

interface ReagentEntry {
  name: string;
  colour: string;
  volume: number;
}

interface Data {
  target?: string;
  is_dead?: boolean;
  consciousness?: number;
  pain?: number;
  circulation?: number;
  oxygenation?: number;
  injuries?: Injuries;
  is_bleeding?: boolean;
  is_bandaged?: boolean;
  timeofdeath?: string;
  body_temperature?: string;
  species?: string;
  core_temperature?: string;
  blood_type?: string;
  blood_volume?: number;
  reagents?: ReagentEntry[];
}

export const HealthAnalyzer = (props) => {
  const { act, data } = useBackend<Data>();

  const [selectedSection, setSelectedSection] = useLocalState<'chest' | string>(
    'selectedSection',
    'chest',
  );

  if (
    selectedSection !== 'chest' &&
    (!data.injuries || !data.injuries[selectedSection])
  ) {
    setSelectedSection('chest');
    return;
  }

  let heartBpm =
    72 +
    0.8 * (100 - Math.min(data.circulation ?? 0, 1.1) * 100) +
    120 *
      Math.exp(
        -Math.pow((Math.min(data.circulation ?? 0, 1.1) * 100 - 10) / 10, 2),
      );

  if ((data.circulation ?? 0) <= 0) {
    heartBpm = 0;
  }

  const heartTickRate = Math.round((20 * 60) / heartBpm);

  return (
    <Window width={510} height={594}>
      <Window.Content class="health_analyzer">
        <div className="interface_main">
          <div className="body_overview">
            <svg width="140" height="320" viewBox="0 0 35 80">
              <defs>
                <clipPath id="consciousnessClip">
                  <rect
                    x="0"
                    y={
                      80 -
                      clamp01(
                        (data.consciousness ?? 1) >= 0
                          ? (data.consciousness ?? 1)
                          : Math.abs(data.consciousness!),
                      ) *
                        80
                    }
                    width="35"
                    height={
                      clamp01(
                        (data.consciousness ?? 1) >= 0
                          ? (data.consciousness ?? 1)
                          : Math.abs(data.consciousness!),
                      ) * 80
                    }
                  />
                </clipPath>
                <filter id="staticNoise">
                  <feTurbulence
                    type="fractalNoise"
                    baseFrequency="1.2"
                    numOctaves="1"
                    seed="1"
                    result="noise"
                  >
                    <animate
                      attributeName="seed"
                      values="1;2;3;4;5;6;7;8;9;10"
                      dur="0.12s"
                      repeatCount="indefinite"
                    />
                  </feTurbulence>

                  <feColorMatrix type="saturate" values="0" />

                  <feComponentTransfer>
                    <feFuncR type="discrete" tableValues="0 1" />
                    <feFuncG type="discrete" tableValues="0 1" />
                    <feFuncB type="discrete" tableValues="0 1" />
                  </feComponentTransfer>
                </filter>
              </defs>

              <path
                d={bodyPart}
                stroke="none"
                fill={(data.consciousness ?? 0) >= 0 ? 'green' : 'red'}
                clipPath="url(#consciousnessClip)"
              />
              <path d={bodyPart} stroke="white" fill="none" strokeWidth="0.5" />

              {bodyParts.map((x) => (
                <>
                  <path className="areaPath" d={x.outline} stroke="none" />
                  <path
                    className="areaHitbox"
                    d={x.hitbox}
                    onClick={() => {
                      setSelectedSection(x.zoneName);
                    }}
                    stroke="none"
                    fill="transparent"
                  />
                  {!!data.injuries &&
                    data.injuries[x.zoneName]?.filter(
                      (x) => x.severity === 2 || x.severity === undefined,
                    )?.length > 0 && (
                      <>
                        <circle
                          cx={x.center.x}
                          cy={x.center.y}
                          r={3}
                          stroke={GetWorstInjuryColour(
                            data.injuries[x.zoneName].filter(
                              (x) =>
                                x.severity === 2 || x.severity === undefined,
                            ),
                          )}
                          fill="#212637"
                        />
                        <text
                          x={x.center.x}
                          y={x.center.y}
                          fill="white"
                          fontSize={4}
                          text-anchor="middle"
                          dominant-baseline="middle"
                        >
                          {data.injuries[x.zoneName]?.length}
                        </text>
                      </>
                    )}
                </>
              ))}
              {data.is_dead && (
                <>
                  <rect
                    x="0"
                    y="0"
                    width="35"
                    height="80"
                    fill="rgba(0, 0, 0, 1)"
                    filter="url(#staticNoise)"
                    opacity={0.5}
                  />
                  <rect
                    x="0"
                    y="26"
                    width="35"
                    height="11"
                    fill="rgba(0, 0, 0, 0.7)"
                  />
                  <text
                    x="16"
                    y="32"
                    fill="white"
                    fontSize="6"
                    fontWeight="bold"
                    textAnchor="middle"
                    dominantBaseline="middle"
                  >
                    Deceased
                  </text>
                </>
              )}
            </svg>
            <div className="chart_container heart">
              Circulation
              <ScrollingChart
                className="chart"
                generator={(params) =>
                  params.steps % heartTickRate === 0
                    ? (data.circulation ?? 0) * 0.5 + 0.25
                    : 0.25
                }
                frameRate={20}
                maxValues={60}
                lineColour="lime"
                label={
                  <>
                    <p>{Math.round(heartBpm) + ' BPM'}</p>
                    <p>{Math.round((data.circulation ?? 0) * 100) + '%'}</p>
                  </>
                }
              />
            </div>
            <div className="chart_container oxygen">
              Oxygen
              <ScrollingChart
                className="chart"
                generator={(params) => (data.oxygenation ?? 0) * 0.75}
                frameRate={10}
                maxValues={60}
                lineColour="cyan"
                label={Math.round((data.oxygenation ?? 0) * 100) + '%'}
              />
            </div>
            <div className="chart_container blood">
              Blood
              <ScrollingChart
                className="chart"
                generator={(params) => (data.blood_volume ?? 0) / 650}
                frameRate={10}
                maxValues={60}
                lineColour="red"
                label={Math.round(data.blood_volume ?? 0) + ' cl'}
              />
            </div>
            <div className="chart_container pain">
              Pain
              <ScrollingChart
                className="chart"
                generator={(params) => (data.pain ?? 0) / 120 + 0.1}
                frameRate={10}
                maxValues={60}
                lineColour="yellow"
                label={Math.round(data.pain ?? 0) + '%'}
              />
            </div>
          </div>
          <div className="side_bar">
            <div>{data.blood_type}</div>
            {MapZone('body', data.injuries!['body'])}
            {selectedSection !== 'body' &&
              !!data.injuries &&
              !!data.injuries[selectedSection] &&
              MapZone(selectedSection, data.injuries![selectedSection])}
            {data.reagents && (
              <Section title="Reagents">
                <div className="injury_row">
                  {data.reagents?.map((x) =>
                    MapInjury({
                      name: x.name,
                      damage: x.volume,
                      heal_text: '',
                    }),
                  )}
                  {data.reagents?.length === 0 && 'No reagents'}
                </div>
              </Section>
            )}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};

const MapZone = (zone: string, injuries: InjuryEntry[]) => {
  return (
    <Section title={zone}>
      <div className="injury_row">
        {injuries.sort((x) => x.severity ?? 0).map(MapInjury)}
        {injuries.length === 0 && 'No injuries'}
      </div>
    </Section>
  );
};

const MapInjury = (injury: InjuryEntry) => {
  return (
    <Tooltip content={injury.heal_text}>
      <div key={injury.name} className="injury_entry">
        <div
          className="injury_icon"
          style={{
            borderColor: GetInjuryColour(injury),
          }}
        >
          {typeof injury.damage === 'number' && injury.damage > 0
            ? injury.damage.toFixed(1)
            : injury.damage !== 0 && injury.damage}
        </div>
        <div>{injury.name}</div>
      </div>
    </Tooltip>
  );
};

function mixColors(color1, color2, amount = 0.5) {
  const hexToRgb = (hex) => {
    hex = hex.replace('#', '');
    return [
      parseInt(hex.slice(0, 2), 16),
      parseInt(hex.slice(2, 4), 16),
      parseInt(hex.slice(4, 6), 16),
    ];
  };

  const rgbToHex = (rgb) =>
    '#' + rgb.map((x) => Math.round(x).toString(16).padStart(2, '0')).join('');

  const a = hexToRgb(color1);
  const b = hexToRgb(color2);

  const mixed = a.map((value, i) => value + (b[i] - value) * amount);

  return rgbToHex(mixed);
}

function GetInjuryColour(injury: InjuryEntry) {
  return typeof injury.damage === 'number' && injury.damage > 0
    ? mixColors('#29ba41', '#b82828', injury.damage / 50)
    : injury.severity === InjurySeverity.None
      ? '#29ba41'
      : injury.severity === InjurySeverity.Healing
        ? '#29ba41'
        : '#b82828';
}

function GetWorstInjuryColour(injuries: InjuryEntry[]) {
  const firstInjury = injuries
    .sort((x) => -(typeof x.damage === 'number' && x.damage > 0 ? x.damage : 0))
    .sort((x) => -(x.severity ?? 0))[0];
  if (!firstInjury) {
    return undefined;
  }
  return GetInjuryColour(firstInjury);
}
