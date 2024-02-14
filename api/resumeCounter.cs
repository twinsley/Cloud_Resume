using System.Net;
using System.Text.Json;
using api.entities;
using Azure;
using Azure.Data.Tables;
using Azure.Data.Tables.Models;
using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace api
{
    public class resumeCounter
    {
        private readonly ILogger _logger;

        public resumeCounter(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<resumeCounter>();
        }

        [Function("resumeCounter")]
        public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req )
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            ResponseBody responseBody = new ResponseBody();
            // Handle request body. May not be needed
            try
            {
                string requestBody = new StreamReader(req.Body).ReadToEnd();
                CounterPost counterPost = JsonSerializer.Deserialize<CounterPost>(requestBody);
                _logger.LogInformation("Request IP: " + counterPost.Ip);
            }
            catch (Exception e)
            {
                _logger.LogError($"Failed to process body. Exception {e}");
            }

            try
            {
                // get table storage , initialize connection and get table
                var tableEndpoint = Environment.GetEnvironmentVariable("AZURE_STORAGETABLE_RESOURCEENDPOINT");
                var credential = new DefaultAzureCredential();
                var tableServiceClient = new TableServiceClient(
                    new Uri(tableEndpoint),
                    credential);
                var tableClient = tableServiceClient.GetTableClient("ResumeCounter");
                tableClient.CreateIfNotExistsAsync();
           

            _logger.LogInformation("Getting entity...");
            // get the entity for today
            string currentDate = DateTime.Today.ToString();
            var currentDay = tableClient.GetEntityIfExists<ResumeCounterEntity>("Count", "Daily");
            var totalCount = tableClient.GetEntityIfExists<ResumeCounterEntity>("Count", "Total");
            
            var todayCount = new ResumeCounterEntity();
            var newTotal = new ResumeCounterEntity();
                if (!currentDay.HasValue)
                {
                    todayCount.PartitionKey = "Count";
                    todayCount.RowKey = "Daily";
                    todayCount.Count = 1;
                    _logger.LogInformation("No daily entity yet");
                    tableClient.UpsertEntity(todayCount);
                }
                else
                {
                    todayCount = currentDay.Value;
                    if (currentDay.Value.Count == null)
                    {
                        todayCount.Count = 1;
                        
                    }
                    else if (currentDay.Value.Count> 1 && currentDay.Value.Timestamp.Value.AddHours(-5).Date != DateTime.Today.Date)
                    {
                        _logger.LogInformation("Hit daily reset");
                        _logger.LogInformation($"{currentDay.Value.Timestamp.Value.AddHours(-5)} compared to {DateTime.Today}");
                        todayCount.Count = 1;
                    }
                    else
                    {
                        todayCount.Count = currentDay.Value.Count + 1;
                    }

                    responseBody.DailyCount = todayCount.Count;
                    tableClient.UpsertEntity(todayCount);
                    _logger.LogInformation("Successfully updated daily count: " + todayCount.Count);
                }

                if (!totalCount.HasValue)
                {
                    newTotal.PartitionKey = "Count";
                    newTotal.RowKey = "Total";
                    newTotal.Count = 1;
                    tableClient.UpsertEntity(newTotal);
                }
                else
                {
                    newTotal = totalCount.Value;
                    if (newTotal.Count != null)
                    {
                        newTotal.Count = totalCount.Value.Count + 1;
                    }
                    else
                    {
                        newTotal.Count = 1;
                    }

                    responseBody.TotalCount = newTotal.Count;
                    tableClient.UpsertEntity(newTotal);
                    _logger.LogInformation("Successfully updated total count: " + newTotal.Count);
                }
            }
            catch (Exception e)
            {
                _logger.LogCritical("Failed to log count to database. Error: " + e);
                
            }

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.WriteAsJsonAsync(responseBody);
            //response.WriteString("Welcome to Azure Functions!");

            return response;
        }
    }
}
