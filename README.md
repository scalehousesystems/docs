# ScaleHouse Systems Documentation

This directory contains the documentation for ScaleHouse Systems, powered by [Mintlify](https://mintlify.com).

## Setup

### 1. Clone the Documentation Repository

The documentation is maintained in a separate repository. Clone it into this directory:

```bash
git clone https://github.com/scalehousesystems/docs.git .
```

Or if you already have the docs repository cloned elsewhere:

```bash
# From the scalehousesystems root directory
cp -r /path/to/docs/* docs/
```

### 2. Install Dependencies

Install Mintlify CLI globally:

```bash
npm install -g mintlify
```

Or use npx to run commands without global installation.

### 3. Run Local Development Server

Start the Mintlify development server:

```bash
mintlify dev
```

The documentation will be available at `http://localhost:3000` (or the port specified by Mintlify).

## Configuration

### Environment Variables

Configure the Mintlify base URL for local vs production:

- **Local Development**: Set `MINTLIFY_BASE_URL=http://localhost:3000` in your `.env.local`
- **Production**: Set `MINTLIFY_BASE_URL=https://scalehousesystems.mintlify.app` in your production environment

The Next.js proxy route (`src/app/docs/[[...slug]]/route.ts`) uses this environment variable to determine where to fetch documentation from.

### Mintlify Configuration

The main configuration file is `mint.json` in the docs directory. This file defines:
- Navigation structure
- API documentation
- Theme settings
- Custom pages

## Troubleshooting

### Port Already in Use

If port 3000 is already in use by your Next.js dev server:

1. Stop the Next.js dev server temporarily, or
2. Run Mintlify on a different port: `mintlify dev --port 3001`
3. Update `MINTLIFY_BASE_URL` to match the new port

### Proxy Errors

If you see proxy errors when accessing `/docs` in the Next.js app:

1. **Check Mintlify is running**: Ensure `mintlify dev` is running
2. **Verify MINTLIFY_BASE_URL**: Check that the environment variable matches the Mintlify dev server URL
3. **Check network connectivity**: Ensure the Next.js server can reach the Mintlify server
4. **Review proxy logs**: Check the Next.js console for detailed error messages

### MDX Live Reload Not Working

If changes to MDX files don't automatically reload:

1. **Check Mintlify watcher**: Ensure Mintlify is watching for file changes
2. **Restart Mintlify**: Stop and restart `mintlify dev`
3. **Clear cache**: Delete `.mintlify` directory if it exists and restart
4. **Check file permissions**: Ensure you have write permissions to the docs directory

### Base Tag Issues

If relative links or assets aren't resolving correctly:

- The proxy route injects `<base href="/docs/">` into the HTML
- Ensure the base tag is present in the rewritten HTML
- Check browser console for 404 errors on assets
- Verify the rewrite script is also injected (it intercepts Mintlify URLs in JavaScript)

## Development Workflow

1. **Make changes**: Edit MDX files in the `docs` directory
2. **Preview locally**: Run `mintlify dev` to see changes
3. **Test proxy**: Access `/docs` in your Next.js app to test the proxy integration
4. **Commit changes**: Commit both the docs changes and any proxy route updates

## Production Deployment

When deploying to production:

1. Ensure `MINTLIFY_BASE_URL` is set to the production Mintlify URL
2. The proxy route will automatically fetch from the production Mintlify instance
3. Documentation is cached with appropriate cache headers for performance

## Additional Resources

- [Mintlify Documentation](https://docs.mintlify.com)
- [Mintlify MDX Guide](https://docs.mintlify.com/mdx)
- [ScaleHouse Systems Docs Repository](https://github.com/scalehousesystems/docs)

