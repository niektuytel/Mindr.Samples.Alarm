using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Alarm.Api.Models
{
    public class CloudMessageResponse
    {
        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("success")]
        public int Success { get; set; }

        [JsonPropertyName("failure")]
        public int Failure { get; set; }

        [JsonPropertyName("canonical_ids")]
        public int CanonicalIds { get; set; }

        [JsonPropertyName("results")]
        public List<FcmResult> Results { get; set; }
    }

    public class FcmResult
    {
        [JsonPropertyName("message_id")]
        public string MessageId { get; set; }

        [JsonPropertyName("error")]
        public string Error { get; set; }
    }

}
