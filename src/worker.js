const ROUTES = {
  '/full': '/full.html',
  '/report': '/report.html',
};

function withCache(response) {
  const headers = new Headers(response.headers);
  headers.set('Cache-Control', 'public, max-age=300, s-maxage=3600');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/') {
      return Response.redirect(`${url.origin}/full`, 302);
    }

    const assetPath = ROUTES[url.pathname] || url.pathname;
    const assetUrl = new URL(assetPath, url.origin);
    const response = await env.ASSETS.fetch(new Request(assetUrl, request));

    if (response.status === 404 && !assetPath.includes('.')) {
      return new Response('Not found', { status: 404 });
    }

    return withCache(response);
  },
};
