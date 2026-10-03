import { useBackend } from 'tgui/backend';
import { Section } from 'tgui/components';
import ScrollingChart from 'tgui/components/ScrollingChart';

import { Window } from '../layouts';

interface InjuryEntry {
  name: string;
  heal_text: string;
  damage?: number | string;
  severity?: number;
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
    <Window width={500} height={580}>
      <Window.Content scrollable class="health_analyzer">
        <div className="top_bar">
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
        <div className="top_bar">
          <ScrollingChart
            className="chart"
            generator={(params) => (data.oxygenation ?? 0) * 0.75}
            frameRate={10}
            maxValues={60}
            lineColour="cyan"
            label={Math.round((data.oxygenation ?? 0) * 100) + '%'}
          />
        </div>
        <div className="top_bar">
          <ScrollingChart
            className="chart"
            generator={(params) => (data.blood_volume ?? 0) / 650}
            frameRate={10}
            maxValues={60}
            lineColour="red"
            label={Math.round(data.blood_volume ?? 0) + ' cl'}
          />
        </div>
        <div className="top_bar">
          <ScrollingChart
            className="chart"
            generator={(params) => (data.pain ?? 0) / 120 + 0.1}
            frameRate={10}
            maxValues={60}
            lineColour="yellow"
            label={Math.round(data.pain ?? 0) + '%'}
          />
        </div>
        <div>{data.is_dead ? 'Dead' : 'Alive'}</div>
        <div>Consciousness: {data.consciousness ?? 0}</div>
        <div>Pain: {data.pain ?? 0}</div>
        <div>Circulation: {data.circulation ?? 0}</div>
        <div>Oxygenation: {data.oxygenation ?? 0}</div>
        <div>{data.blood_type}</div>
        {Object.keys(data.injuries ?? []).map((x) =>
          MapZone(x, data.injuries![x]),
        )}
        <Section title="Reagents">
          <div className="injury_row">
            {data.reagents?.map((x) =>
              MapInjury({
                name: x.name,
                damage: x.volume,
                heal_text: '',
              }),
            )}
          </div>
        </Section>
      </Window.Content>
    </Window>
  );
};

const MapZone = (zone: string, injuries: InjuryEntry[]) => {
  return (
    <Section title={zone}>
      <div className="injury_row">
        {injuries.sort((x) => x.severity ?? 0).map(MapInjury)}
      </div>
    </Section>
  );
};

const MapInjury = (injury: InjuryEntry) => {
  return (
    <div key={injury.name} className="injury_entry">
      <div
        className="injury_icon"
        style={{
          borderColor:
            typeof injury.damage === 'number'
              ? mixColors('#29ba41', '#b82828', injury.damage / 50)
              : mixColors('#29ba41', '#b82828', (injury.severity ?? 2) / 2),
        }}
      >
        {typeof injury.damage === 'number'
          ? injury.damage.toFixed(1)
          : injury.damage}
      </div>
      <div>{injury.name}</div>
    </div>
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
