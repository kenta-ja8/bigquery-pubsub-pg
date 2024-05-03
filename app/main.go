package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"cloud.google.com/go/bigquery"
	"cloud.google.com/go/pubsub"
)

var datasetID = "example_dataset"
var tableID = "example_table"

func publishToPubSub(ctx context.Context, projectID, key string) {
	client, err := pubsub.NewClient(ctx, projectID)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	topic := client.Topic("example-topic")
	res := topic.Publish(ctx, &pubsub.Message{
		Data: []byte("{ \"add_column\": \"X3\", \"dataXXX\": \"Hello, World!" + key + "\"}"),
	})
	_, err = res.Get(ctx)
	if err != nil {
		log.Println(err)
	}
}

func insertToBigQuery(ctx context.Context, projectID, key string) {
	client, err := bigquery.NewClient(ctx, projectID)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	type item struct {
		AddColumn string `bigquery:"add_column"`
		Data      string `bigquery:"data"`
	}

	if err := client.Dataset(datasetID).Table(tableID).Inserter().Put(ctx, []item{{
		AddColumn: "Direct BigQuery Insert",
		Data:      "Hello, World!" + key,
	}}); err != nil {
		log.Printf("failed to put data: %#v", err.Error())
	}

}

func main() {
	log.Println("---Start---")
	defer log.Println("---End---")

	ctx := context.Background()
	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		panic("GOOGLE_CLOUD_PROJECT must be set")
	}

	startTime := time.Now()

	var sum time.Duration
	for i := 0; i < 100; i++ {
		startInsertTime := time.Now()
		key := fmt.Sprintf("key%d", i)
		insertToBigQuery(ctx, projectID, key)
		elapsedInsert := time.Since(startInsertTime)
		log.Printf("insert time: %s\n", elapsedInsert)
		sum += elapsedInsert
	}
	log.Printf("sum time: %s\n", sum)

	elapsed := time.Since(startTime)
	log.Printf("process time: %s\n", elapsed)

	time.Sleep(3 * time.Second)
}
