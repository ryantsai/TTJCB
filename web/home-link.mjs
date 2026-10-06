// A page above the game to go back to (the games homepage, for the copy of this
// game that sits beside others). The page that hosts the game says so with a
// home.json file next to it, {"url": "../"}; without one there is no button,
// as on this project's own GitHub Pages site.
export async function loadHome(assetUrl, fetchFile = globalThis.fetch) {
  try {
    const response = await fetchFile(assetUrl('./home.json'));
    if (!response.ok) return null;
    const { url } = await response.json();
    return typeof url === 'string' && url ? url : null;
  } catch { return null; }
}

// The game draws the button on its title screen once homeAvailable is set, and
// bumps homeRevision when it is clicked.
export function connectHome(viewModel, url, navigate) {
  const available = viewModel.boolean('homeAvailable');
  const revision = viewModel.number('homeRevision');
  if (!available || !revision) throw new Error('The Rive build is missing home bindings.');
  let lastRevision = revision.value;
  const clicked = () => {
    if (revision.value === lastRevision) return;
    lastRevision = revision.value;
    navigate(url);
  };
  revision.on(clicked);
  available.value = true;
  return () => { revision.off(clicked); available.value = false; };
}
