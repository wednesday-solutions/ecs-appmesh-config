import express from 'express';
import dotenv from 'dotenv';

let app;
export const init = () => {
  dotenv.config({ path: `.env.${process.env.ENVIRONMENT_NAME}` });
  if (!app) {
    app = express();
  }
  
  const port = process.env.PORT || 3000;
  app.use(express.json());

  app.get('/', (req, res) => {
    try {
      const message = 'Service 1 is up and running, updated testing CD !!!';
      res.json({message});
    } catch (error) {
      throw new Error(error)
    }
  });

  app.get('/healthcheck', (req, res) => {
    try {
      console.log('Service 1.1 is healthy.');
      const message = 'Service 1.1 is healthy!';
      res.json({message});
    } catch (error) {
      throw new Error(error)
    }
  });

  // error handler middleware
  app.use((error, req, res, next) => {
    res.status(500).json({
      success: false,
      message: error.message || 'Something went wrong!!'
    });
  })

  app.use((req, res, next) => {
    res.status(404).send({
      status: 404,
      error: "Not found"
    })
  })
  
  app.listen(port, ()=> {
    console.log('Server 1 is up on port ' + port);
  });
};

init();

export { app };