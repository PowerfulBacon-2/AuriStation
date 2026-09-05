import { useDispatch, useSelector } from 'tgui/backend';

import { selectStatPanel } from './selectors';

export const useStatPanel = () => {
  const state = useSelector(selectStatPanel);
  const dispatch = useDispatch();
  return {
    ...state,
    toggle: () => dispatch({ type: 'stat/toggle' }),
  };
};
