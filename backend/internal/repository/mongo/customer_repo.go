package mongo

import (
	"context"
	"fmt"
	"time"

	"sml-fleet/internal/database"
	"sml-fleet/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// CustomerRepo MongoDB repository สำหรับลูกค้า (Source of Truth)
type CustomerRepo struct {
	mongo *database.MongoDB
}

func NewCustomerRepo(mongo *database.MongoDB) *CustomerRepo {
	return &CustomerRepo{mongo: mongo}
}

func (r *CustomerRepo) collection() *mongo.Collection {
	return r.mongo.Collection("fleet_customers")
}

func (r *CustomerRepo) Insert(ctx context.Context, c *models.Customer) error {
	if c.ID.IsZero() {
		c.ID = primitive.NewObjectID()
	}
	now := time.Now()
	c.CreatedAt = now
	c.UpdatedAt = now
	if c.Status == "" {
		c.Status = "active"
	}
	_, err := r.collection().InsertOne(ctx, c)
	return err
}

func (r *CustomerRepo) Update(ctx context.Context, shopID, id string, updates bson.M) error {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("invalid customer id: %w", err)
	}
	updates["updated_at"] = time.Now()
	_, err = r.collection().UpdateOne(ctx,
		bson.M{"_id": oid, "shop_id": shopID},
		bson.M{"$set": updates},
	)
	return err
}

func (r *CustomerRepo) FindByID(ctx context.Context, shopID, id string) (*models.Customer, error) {
	oid, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, fmt.Errorf("invalid customer id: %w", err)
	}
	var c models.Customer
	err = r.collection().FindOne(ctx, bson.M{"_id": oid, "shop_id": shopID, "deleted_at": nil}).Decode(&c)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CustomerRepo) FindByPhone(ctx context.Context, shopID, phone string) (*models.Customer, error) {
	var c models.Customer
	err := r.collection().FindOne(ctx, bson.M{"shop_id": shopID, "phone": phone, "deleted_at": nil}).Decode(&c)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CustomerRepo) FindByLineUserID(ctx context.Context, shopID, lineUserID string) (*models.Customer, error) {
	var c models.Customer
	err := r.collection().FindOne(ctx, bson.M{"shop_id": shopID, "line_user_id": lineUserID, "deleted_at": nil}).Decode(&c)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *CustomerRepo) Search(ctx context.Context, shopID, keyword string, limit int) ([]*models.Customer, error) {
	filter := bson.M{
		"shop_id":    shopID,
		"deleted_at": nil,
		"$or": []bson.M{
			{"name": bson.M{"$regex": keyword, "$options": "i"}},
			{"phone": bson.M{"$regex": keyword, "$options": "i"}},
			{"company": bson.M{"$regex": keyword, "$options": "i"}},
			{"customer_no": bson.M{"$regex": keyword, "$options": "i"}},
		},
	}
	opts := options.Find().SetLimit(int64(limit)).SetSort(bson.D{{Key: "name", Value: 1}})
	cursor, err := r.collection().Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []*models.Customer
	if err := cursor.All(ctx, &results); err != nil {
		return nil, err
	}
	return results, nil
}

func (r *CustomerRepo) GenerateCustomerNo(ctx context.Context, shopID string) (string, error) {
	count, err := r.collection().CountDocuments(ctx, bson.M{"shop_id": shopID})
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("CUST-%04d", count+1), nil
}
