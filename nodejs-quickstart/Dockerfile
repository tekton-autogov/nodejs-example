FROM ubi8/nodejs-18-minimal

EXPOSE 8080

# Copy the application source and build artifacts from the builder image to this one
COPY src/ $HOME

# Run script uses standard ways to run the application
CMD npm run -d start

