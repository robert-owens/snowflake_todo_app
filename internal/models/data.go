package models

type DataRow struct {
	ID   string `json:"id"`
	Task string `json:"task"`
	Done bool   `json:"done"`
}
