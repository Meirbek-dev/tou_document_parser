# Quick Deploy Instructions

## The Issue
You're seeing an empty page because the Flutter web app needs to be **built** first.

## The Solution (3 Steps)

### Step 1: Build on Your Development Machine

On the machine where you normally run `flutter run -d chrome`:

```bash
# Open terminal in your project directory
cd path/to/ai_reception

# Build the web app
flutter build web --release
```

This creates a `build/web/` folder with your compiled app.

### Step 2: Copy build/web to This Server

Copy the `build/web` folder from your development machine to this Linux server at `/home/user/ai-reception/build/web/`

**Options to transfer:**
- Use WinSCP (Windows)
- Use FileZilla
- Use `scp` command
- Use shared drive

### Step 3: Deploy to Server

Once you have `build/web/` in `/home/user/ai-reception/`, run:

```bash
cd /home/user/ai-reception

# Transfer to deployment server
rsync -avz --progress --delete build/web/ user@192.168.12.35:~/ai_reception/build/web/

# Transfer updated server.py and Dockerfile
scp server.py Dockerfile user@192.168.12.35:~/ai_reception/

# Restart container
ssh user@192.168.12.35 "cd ~/ai_reception && docker-compose down && docker-compose up -d --build"
```

### Step 4: Test

Open in browser: http://192.168.12.35:5040/

You should now see your app! ✅

---

## Alternative: Use build-and-deploy.sh Script

If Flutter is available on this machine, just run:

```bash
./build-and-deploy.sh
```

---

## Need Help?

See `FIX_EMPTY_PAGE.md` for detailed troubleshooting.
