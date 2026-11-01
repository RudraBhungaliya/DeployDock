const app = db.getSiblingDB('deploydock');
app.createUser({
    user: 'deploydock',
    pwd: process.env.MONGO_APP_PASSWORD,
    roles: [{ role: 'readWrite', db: 'deploydock' }],
});
