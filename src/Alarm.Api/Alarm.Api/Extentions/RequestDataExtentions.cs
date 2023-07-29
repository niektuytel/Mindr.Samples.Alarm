using Alarm.Api.Models.AlarmAction;
using Microsoft.Azure.Functions.Worker.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using static Grpc.Core.Metadata;

namespace Alarm.Api.Extentions
{
    internal static class RequestDataExtentions
    {
        public static async Task<AlarmActionOnPush> GetAlarmActionOnPush(this HttpRequestData request)
        {
            var body = await request.ReadAsStringAsync();
            if (string.IsNullOrWhiteSpace(body))
            {
                throw new Exception($"Argument null exception: {{{nameof(body)}:'Invalid data input.'}}");
            }

            var data = JsonSerializer.Deserialize<AlarmActionOnPush>(body);
            if (data == null)
            {
                throw new Exception($"Argument null exception: {{{nameof(data)}:'Invalid data input.'}}");
            }

            return data;
        }
    }
}
