
import { useBackend } from 'tgui/backend';
import { Section } from 'tgui/components';

import { Window } from '../layouts';

type InjuryEntry = {
  name: string,
  heal_text: string,
  damage?: number,
  severity?: number
  effectiveness_modifier?: number,
  bone_armour_modifier?: number,
  skin_armour_modifier?: number,
  pain?: number
}

type Injuries = { [area: string]: InjuryEntry[] }

type Data = {
  target?: string,
  is_dead?: boolean,
  consciousness?: number,
  injuries?: Injuries
}

export const HealthAnalyzer = (props) => {
  const { act, data } = useBackend<Data>();

  return (
    <Window width={500} height={450}>
      <Window.Content scrollable>
        { data.is_dead ? "Dead" : "Alive" }
        Consciousness: { data.consciousness ?? 0 }
        { Object.keys(data.injuries ?? []).map(x => MapZone(x, data.injuries![x])) }
      </Window.Content>
    </Window>
  );
};

const MapZone = (zone: string, injuries: InjuryEntry[]) => {
  return (
    <Section title={zone}>
      { injuries.map(MapInjury) }
    </Section>
  );
};

const MapInjury = (injury: InjuryEntry) => {
  return <div key={injury.name}>{JSON.stringify(injury)}</div>;
};
