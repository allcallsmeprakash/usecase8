const express = require('express');
const app = express();
const port = process.env.PORT || 3001;

// CloudWatch Logs integration
const winston = require('winston');
require('winston-cloudwatch');

// Configure Winston to use CloudWatch
const logger = winston.createLogger({
  transports: [
    new winston.transports.Console(),
    new winston.transports.CloudWatch({
      logGroupName: '/healthcare/appointment-service',
      logStreamName: 'appointment-stream',
      awsRegion: 'ap-south-1', // Update to your region
      jsonMessage: true
    })
  ]
});

app.use(express.json());

// In-memory data store
let appointments = [
  { id: '1', patientId: '1', date: '2023-06-15', time: '10:00', doctor: 'Dr. Smith' },
  { id: '2', patientId: '2', date: '2023-06-16', time: '14:30', doctor: 'Dr. Johnson' }
];

// Middleware to log incoming requests
app.use((req, res, next) => {
  logger.info(`Request received: ${req.method} ${req.originalUrl} from ${req.ip}`);
  next();
});

app.get('/health', (req, res) => {
  logger.info('Health check endpoint hit');
  res.status(200).json({ status: 'OK', service: 'Appointment Service' });
});

app.get('/appointments', (req, res) => {
  logger.info('Fetching all appointments');
  res.json({
    message: 'Appointments retrieved successfully',
    count: appointments.length,
    appointments: appointments
  });
});

app.get('/appointments/:id', (req, res) => {
  const appointment = appointments.find(a => a.id === req.params.id);
  if (appointment) {
    logger.info(`Appointment found for ID: ${req.params.id}`);
    res.json({
      message: 'Appointment found',
      appointment: appointment
    });
  } else {
    logger.warn(`Appointment not found for ID: ${req.params.id}`);
    res.status(404).json({ error: 'Appointment not found' });
  }
});

app.post('/appointments', (req, res) => {
  try {
    const { patientId, date, time, doctor } = req.body;
    if (!patientId || !date || !time || !doctor) {
      logger.warn('Missing required fields in appointment creation');
      return res.status(400).json({ error: 'Patient ID, date, time, and doctor are required' });
    }
    const newAppointment = {
      id: (appointments.length + 1).toString(),
      patientId,
      date,
      time,
      doctor
    };
    appointments.push(newAppointment);
    logger.info(`New appointment created: ${JSON.stringify(newAppointment)}`);
    res.status(201).json({
      message: 'Appointment scheduled successfully',
      appointment: newAppointment
    });
  } catch (error) {
    logger.error(`Error creating appointment: ${error.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/appointments/patient/:patientId', (req, res) => {
  try {
    const patientId = req.params.patientId;
    const patientAppointments = appointments.filter(appt => appt.patientId === patientId);
    if (patientAppointments.length > 0) {
      logger.info(`Found ${patientAppointments.length} appointments for patient ${patientId}`);
      res.json({
        message: `Found ${patientAppointments.length} appointment(s) for patient ${patientId}`,
        appointments: patientAppointments
      });
    } else {
      logger.warn(`No appointments found for patient ${patientId}`);
      res.status(404).json({ message: `No appointments found for patient ${patientId}` });
    }
  } catch (error) {
    logger.error(`Error fetching appointments for patient ${req.params.patientId}: ${error.message}`);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(port, '0.0.0.0', () => {
  logger.info(`Appointment service listening on port ${port}`);
});
