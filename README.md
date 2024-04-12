# Shiny Apps Hosted with Snowflake

**Prerequisites**:
1. **Snowflake Account**: Ensure you have sysadmin privileges, cool with someone who does, or if working in a DEV environment, have the necessary privileges to create a stage, image repository, and compute pool.
2. **Docker**: Docker needs to be installed. Learn more about [Docker](https://www.docker.com/get-started) and [Snowpark Container Services](https://medium.com/snowflake/snowpark-container-services-a-tech-primer-99ff2ca8e741).
3. **Visual Studio Code**: Install VS Code along with the Snowflake extension.

### Deployment Steps:

**Step 1: Set up infrastructure in Snowflake**
- Log in using the Snowflake extension in VS Code. Select a database and schema and then proceed with the following:
  ```sql
  USE ROLE SYSADMIN;
  CREATE STAGE IF NOT EXISTS chase ENCRYPTION = (TYPE='SNOWFLAKE_SSE');
  -- SNOWFLAKE_SEE does server side encryption
  CREATE IMAGE REPOSITORY IF NOT EXISTS images;
  ```

**Step 2: Configure a compute pool**
- Create a compute pool configured as follows:
  ```sql
  CREATE COMPUTE POOL IF NOT EXISTS chases_r_pool
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS;
  ```
  This compute pool provides 2 vCPU, 8 GiB of Memory, and 250GiB of storage, costing approximately $0.22/hr on AWS US East Standard pricing as shown [here](https://www.snowflake.com/legal-files/CreditConsumptionTable.pdf).

**Step 3: Prepare your application**
- Clone my repository or create your own and within it, create a folder named 'data' for any data you might use. Add your `app.R` file and the Dockerfile provided below. Note that your package list may vary based on your Shiny app requirements.
  ```Dockerfile
  # Base R Shiny image
  FROM rocker/shiny

  # Install R dependencies
  RUN R -e "install.packages(c('dplyr', 'ggplot2', 'gapminder', 'tidytext', 'wordcloud', 'tidyverse', 'RColorBrewer', 'shinythemes', 'shinyFiles'))"

  # Copy the Shiny app code
  COPY app.R app.R
  COPY data data

  # Expose the application port
  EXPOSE 8787

  # Run the R Shiny app
  CMD Rscript app.R
  ```

**Step 4: Build and deploy the Docker image**
- Log in to Docker and push the built image to Snowflake:
  ```bash
  docker login <account>.registry.snowflakecomputing.com
  docker build --rm --platform linux/amd64 -t <your_account>.registry.snowflakecomputing.com/<database>/<schema>/images/shiny .
  docker push <your_account>.registry.snowflakecomputing.com/<database>/<schema>/images/shiny
  ```

**Step 5: Create the Service**
- Create and configure the service in Snowflake:
  ```sql
  CREATE SERVICE shiny_app
  IN COMPUTE POOL COMPUTE_POOL_1 
  FROM SPECIFICATION $$
  spec:
    container:
    - name: shiny
      image: sfpscogs-scs.registry.snowflakecomputing.com/cromano/demo/images/shiny
      env:
        DISABLE_AUTH: true
    endpoint:
    - name: shiny
      port: 8787
      public: true
  $$
  MIN_INSTANCES=1 
  MAX_INSTANCES=1;
  ```

**Step 6: Manage and get logs for the service**
- Useful commands for service management:
  ```sql
  desc service shiny_app;
  select system$get_service_status('shiny_app');
  select system$get_service_logs('shiny_app','0', 'shiny',100);
  ```

**Step 7: Access your Shiny app**
- Retrieve and use the URL for your hosted Shiny app:
  ```sql
  show endpoints in service shiny_app;
  ```
  ![image](https://github.com/cromano8/Shiny_Snowflake/assets/59093254/454c11b2-b13b-4b62-bb90-686f2e7148d7)

  Use the URL from `ingress_url` to access your Shiny app in a secure Snowflake environment. This URL can be shared with anyone who has appropriate access privileges.

![image](https://github.com/cromano8/Shiny_Snowflake/assets/59093254/939def4b-3339-4d27-adbf-9f310b16e6af)

### About this app:
This example uses a Shiny app that analyzes three plays by Shakespeare, a project that was the first Shiny App I ever deployed as part of my master's program many years ago.
