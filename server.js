const dns = require('dns');
const { execSync } = require('child_process');

// Auto-discover router/gateway and active DNS servers from the local system
const detectedDns = [];
try {
    const ipconfig = execSync('ipconfig /all', { encoding: 'utf8' });
    const matches = ipconfig.matchAll(/(?:Default Gateway|DNS Servers)[ .:]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/g);
    for (const m of matches) {
        const ip = m[1].trim();
        if (ip && !ip.startsWith('0.') && !ip.startsWith('127.') && !detectedDns.includes(ip)) {
            detectedDns.push(ip);
        }
    }
} catch (_) {}

// Fallback to fast public DNS if gateway discovery fails
const candidateDns = [...detectedDns, '1.1.1.1', '8.8.8.8', '8.8.4.4'].filter(
    (v, i, a) => a.indexOf(v) === i
);

const resolver = new dns.Resolver();
try {
    dns.setDefaultResultOrder('ipv4first');
    if (candidateDns.length > 0) {
        dns.setServers(candidateDns);
        resolver.setServers(candidateDns);
    }
} catch (e) {
    console.warn('DNS server configuration notice:', e.message);
}

// Custom lookup function that uses the discovered DNS resolver to prevent ECONNREFUSED/getaddrinfo on Windows
function customLookup(hostname, options, callback) {
    if (typeof options === 'function') {
        callback = options;
        options = {};
    }
    resolver.resolve4(hostname, (err, addresses) => {
        if (err || !addresses || addresses.length === 0) {
            return dns.lookup(hostname, options, callback);
        }
        if (options && options.all) {
            return callback(null, addresses.map(addr => ({ address: addr, family: 4 })));
        }
        return callback(null, addresses[0], 4);
    });
}

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Check land.env first, then fallback to .env
if (fs.existsSync(path.resolve(__dirname, 'land.env'))) {
    dotenv.config({ path: path.resolve(__dirname, 'land.env') });
}
if (!process.env.MONGO_URI && fs.existsSync(path.resolve(__dirname, '.env'))) {
    dotenv.config({ path: path.resolve(__dirname, '.env') });
}

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;

// ==========================================
// 1. MIDDLEWARE
// ==========================================
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cors({ origin: '*' }));

app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// ==========================================
// 2. CONNECT TO MONGODB ATLAS (With Auto-Retry)
// ==========================================
if (!MONGO_URI) {
    console.error(
        'MongoDB connection failed: MONGO_URI is missing. Check your land.env or .env file.'
    );
    process.exit(1);
}

const mongooseOptions = {
    serverSelectionTimeoutMS: 15000,
    connectTimeoutMS: 20000,
    socketTimeoutMS: 45000,
    family: 4, // Force IPv4 to prevent IPv6 DNS hangs on Windows
    lookup: customLookup,
};

let isConnecting = false;
async function connectToMongo() {
    if (mongoose.connection.readyState === 1 || isConnecting) return;
    isConnecting = true;
    try {
        console.log('🔄 Connecting to MongoDB Atlas...');
        await mongoose.connect(MONGO_URI, mongooseOptions);
        console.log('============================================');
        console.log('✅ Connected to MongoDB Atlas successfully!');
        console.log(`📁 Database: ${mongoose.connection.name}`);
        console.log(`🌐 MongoDB host: ${mongoose.connection.host}`);
        console.log('============================================');
    } catch (error) {
        console.error('❌ MongoDB Atlas connection error:', error.message);
        console.log('🔄 Retrying MongoDB connection in 5 seconds...');
        setTimeout(connectToMongo, 5000);
    } finally {
        isConnecting = false;
    }
}

mongoose.connection.on('disconnected', () => {
    console.warn('⚠️ MongoDB disconnected.');
    if (mongoose.connection.readyState === 0 && !isConnecting) {
        setTimeout(connectToMongo, 3000);
    }
});

mongoose.connection.on('error', (err) => {
    console.error('❌ MongoDB runtime error:', err.message);
});

connectToMongo();

// ==========================================
// 3. DATABASE SCHEMAS
// ==========================================

// User Schema
const userSchema = new mongoose.Schema({
    name: { type: String, trim: true, default: '' },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    phone: { type: String, trim: true, default: '' },
    password: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// Land Measurement Schema
const landSchema = new mongoose.Schema({
    id: { type: String, index: true },
    userEmail: {
        type: String,
        required: true,
        lowercase: true,
        trim: true,
        index: true
    },
    fieldName: {
        type: String,
        default: () => `Field Plot ${Math.floor(1000 + Math.random() * 9000)}`
    },
    areaSize: { type: String, required: true },
    areaSqMeters: { type: Number, default: 0 },
    measurementType: { type: String, default: 'GPS' },
    latitude: { type: Number, default: 0.0 },
    longitude: { type: Number, default: 0.0 },
    coordinates: { type: Array, default: [] },
    boundary: { type: Array, default: [] },
    crop: { type: String, default: '' },
    season: { type: String, default: '' },
    irrigation: { type: String, default: '' },
    soilType: { type: String, default: '' },
    notes: { type: String, default: '' },

    // Agriculture Estimator Fields Integration
    totalBudget: { type: Number, default: 0 },
    seedsCost: { type: Number, default: 0 },
    fertilizerCost: { type: Number, default: 0 },
    seedRequirements: {
        quantityKg: { type: Number, default: 0 },
        ratePerKg: { type: Number, default: 0 }
    },
    fertilizerBreakdown: {
        ureaBags: { type: Number, default: 0 },
        dapBags: { type: Number, default: 0 },
        mopBags: { type: Number, default: 0 },
        manureTons: { type: Number, default: 0 }
    },
    createdAt: { type: Date, default: Date.now }
});

const Land = mongoose.model('Land', landSchema);

// ==========================================
// 4. ROOT AND HEALTH ROUTES
// ==========================================

app.get('/', (req, res) => {
    res.json({
        app: 'Intelligent Land Measurement Backend API',
        status: 'online',
        database: mongoose.connection.readyState === 1
            ? 'connected'
            : 'disconnected',
        databaseName:
            mongoose.connection.name || 'intelligent_land_measurement',
        timestamp: new Date().toISOString()
    });
});

app.get('/api/health', (req, res) => {
    const isDbConnected = mongoose.connection.readyState === 1;

    res.status(isDbConnected ? 200 : 503).json({
        status: isDbConnected ? 'ok' : 'db_offline',
        database: isDbConnected ? 'connected' : 'connecting_or_error',
        databaseName:
            mongoose.connection.name || 'intelligent_land_measurement'
    });
});

// ==========================================
// 5. USER REGISTRATION (With Bcrypt Hashing)
// ==========================================

app.post('/api/register', async (req, res) => {
    try {
        const { name, email, phone, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Email and password are required.'
            });
        }

        const normalizedEmail = email.toLowerCase().trim();

        const existingUser = await User.findOne({
            email: normalizedEmail
        });

        if (existingUser) {
            return res.status(400).json({
                success: false,
                error: 'An account with this email already exists.'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new User({
            name: name ? name.trim() : '',
            email: normalizedEmail,
            phone: phone ? phone.trim() : '',
            password: hashedPassword
        });

        const savedUser = await newUser.save();

        console.log(`[AUTH] User registered: ${savedUser.email}`);

        res.status(201).json({
            success: true,
            message: 'User registered successfully!',
            user: {
                id: savedUser._id,
                name: savedUser.name,
                email: savedUser.email,
                phone: savedUser.phone
            }
        });
    } catch (error) {
        console.error('[AUTH ERROR] Register failed:', error.message);

        res.status(500).json({
            success: false,
            error: 'Registration failed. Please try again.'
        });
    }
});

// ==========================================
// 6. USER LOGIN (With Bcrypt Password Verification)
// ==========================================

app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                error: 'Please enter both email and password.'
            });
        }

        const normalizedEmail = email.toLowerCase().trim();

        const user = await User.findOne({
            email: normalizedEmail
        });

        if (!user) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password. Please register first.'
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({
                success: false,
                error: 'Invalid email or password.'
            });
        }

        console.log(`[AUTH] User logged in: ${user.email}`);

        res.status(200).json({
            success: true,
            message: 'Login successful!',
            user: {
                id: user._id,
                name: user.name || user.email.split('@')[0],
                email: user.email,
                phone: user.phone
            }
        });
    } catch (error) {
        console.error('[AUTH ERROR] Login failed:', error.message);

        res.status(500).json({
            success: false,
            error: 'Login failed. Please try again.'
        });
    }
});

// ==========================================
// 7. GET LAND MEASUREMENTS FOR A USER
// ==========================================

app.get('/api/lands/:email', async (req, res) => {
    try {
        const userEmail = req.params.email.toLowerCase().trim();

        const lands = await Land.find({
            userEmail: userEmail
        }).sort({ createdAt: -1 });

        res.status(200).json(lands);
    } catch (error) {
        console.error('[LAND ERROR] Fetch failed:', error.message);

        res.status(500).json({
            error: 'Failed to fetch land measurements.'
        });
    }
});

// ==========================================
// 8. SAVE OR UPDATE A LAND MEASUREMENT (With Estimator Support)
// ==========================================

app.post('/api/lands', async (req, res) => {
    try {
        const {
            id,
            userEmail,
            fieldName,
            areaSize,
            areaSqMeters,
            measurementType,
            latitude,
            longitude,
            coordinates,
            boundary,
            crop,
            season,
            irrigation,
            soilType,
            notes,
            totalBudget,
            seedsCost,
            fertilizerCost,
            seedRequirements,
            fertilizerBreakdown
        } = req.body;

        const email = (userEmail || 'user@example.com')
            .toLowerCase()
            .trim();

        if (id) {
            const existing = await Land.findOne({
                id: id,
                userEmail: email
            });

            if (existing) {
                if (fieldName !== undefined) existing.fieldName = fieldName.trim();
                if (areaSize !== undefined) existing.areaSize = areaSize;
                if (areaSqMeters !== undefined) existing.areaSqMeters = areaSqMeters;
                if (measurementType !== undefined) existing.measurementType = measurementType;
                if (latitude !== undefined) existing.latitude = latitude;
                if (longitude !== undefined) existing.longitude = longitude;
                if (coordinates !== undefined) existing.coordinates = coordinates;
                if (boundary !== undefined) existing.boundary = boundary;
                if (crop !== undefined) existing.crop = crop;
                if (season !== undefined) existing.season = season;
                if (irrigation !== undefined) existing.irrigation = irrigation;
                if (soilType !== undefined) existing.soilType = soilType;
                if (notes !== undefined) existing.notes = notes;
                if (totalBudget !== undefined) existing.totalBudget = totalBudget;
                if (seedsCost !== undefined) existing.seedsCost = seedsCost;
                if (fertilizerCost !== undefined) existing.fertilizerCost = fertilizerCost;
                if (seedRequirements !== undefined) existing.seedRequirements = seedRequirements;
                if (fertilizerBreakdown !== undefined) existing.fertilizerBreakdown = fertilizerBreakdown;

                const updated = await existing.save();

                console.log(
                    `[LAND] Updated field: "${updated.fieldName}" (${updated.areaSize})`
                );

                return res.status(200).json({
                    message: 'Land data updated successfully!',
                    data: updated
                });
            }
        }

        const newLand = new Land({
            id: id || Date.now().toString(),
            userEmail: email,
            fieldName:
                fieldName && fieldName.trim() !== ''
                    ? fieldName.trim()
                    : undefined,
            areaSize: areaSize || `${areaSqMeters || 0} sq meters`,
            areaSqMeters: areaSqMeters || 0,
            measurementType: measurementType || 'GPS',
            latitude: latitude || 0.0,
            longitude: longitude || 0.0,
            coordinates: coordinates || [],
            boundary: boundary || coordinates || [],
            crop: crop || '',
            season: season || '',
            irrigation: irrigation || '',
            soilType: soilType || '',
            notes: notes || '',
            totalBudget: totalBudget || 0,
            seedsCost: seedsCost || 0,
            fertilizerCost: fertilizerCost || 0,
            seedRequirements: seedRequirements || {},
            fertilizerBreakdown: fertilizerBreakdown || {}
        });

        const savedLand = await newLand.save();

        console.log(
            `[LAND] Saved field: "${savedLand.fieldName}" for ${email}`
        );

        res.status(201).json({
            message: 'Land data saved successfully!',
            data: savedLand
        });
    } catch (error) {
        console.error('[LAND ERROR] Save failed:', error.message);

        res.status(500).json({
            error: 'Failed to save land measurement.'
        });
    }
});

// ==========================================
// 9. UPDATE A LAND MEASUREMENT BY ID
// ==========================================

app.put('/api/lands/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const updateData = req.body;

        const updated = await Land.findOneAndUpdate(
            {
                $or: [
                    {
                        _id: mongoose.isValidObjectId(id) ? id : null
                    },
                    { id: id }
                ]
            },
            { $set: updateData },
            { new: true, runValidators: true }
        );

        if (!updated) {
            return res.status(404).json({
                error: 'Land record not found.'
            });
        }

        res.status(200).json({
            message: 'Land updated successfully!',
            data: updated
        });
    } catch (error) {
        console.error('[LAND ERROR] Update failed:', error.message);

        res.status(500).json({
            error: 'Failed to update land measurement.'
        });
    }
});

// ==========================================
// 10. DELETE A LAND MEASUREMENT BY ID
// ==========================================

app.delete('/api/lands/:id', async (req, res) => {
    try {
        const id = req.params.id;

        const deleted = await Land.findOneAndDelete({
            $or: [
                {
                    _id: mongoose.isValidObjectId(id) ? id : null
                },
                { id: id }
            ]
        });

        if (!deleted) {
            return res.status(404).json({
                error: 'Land record not found.'
            });
        }

        console.log(`[LAND] Deleted field id: ${id}`);

        res.status(200).json({
            message: 'Land record deleted successfully!'
        });
    } catch (error) {
        console.error('[LAND ERROR] Delete failed:', error.message);

        res.status(500).json({
            error: 'Failed to delete land measurement.'
        });
    }
});

// ==========================================
// 11. START SERVER
// ==========================================

function getLocalIpAddresses() {
    const interfaces = os.networkInterfaces();
    const addresses = [];
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                addresses.push(iface.address);
            }
        }
    }
    return addresses;
}

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server is listening on port ${PORT}`);
    console.log('📱 Phone access endpoints:');
    const ips = getLocalIpAddresses();
    ips.forEach(ip => console.log(`   • Wi-Fi LAN:   http://${ip}:${PORT}`));
    console.log(`   • ADB Reverse: http://127.0.0.1:${PORT}`);
    console.log(`💻 Android emulator: http://10.0.2.2:${PORT}`);
    console.log(`💻 Local computer:   http://localhost:${PORT}`);
});