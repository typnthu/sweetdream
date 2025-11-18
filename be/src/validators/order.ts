import Joi from 'joi';

const customerSchema = Joi.object({
  name: Joi.string().required().min(1).max(100),
  email: Joi.string().email().required(),
  phone: Joi.string().optional().allow('').max(20),
  address: Joi.string().required().min(1).max(500)
});

const orderItemSchema = Joi.object({
  productId: Joi.number().integer().positive().required(),
  size: Joi.string().required().min(1).max(20),
  price: Joi.number().positive().required(),
  quantity: Joi.number().integer().positive().required()
});

export const orderSchema = Joi.object({
  customer: customerSchema.required(),
  items: Joi.array().items(orderItemSchema).min(1).required(),
  notes: Joi.string().optional().allow('').max(500)
});

export const validateOrder = (data: any) => {
  return orderSchema.validate(data, { abortEarly: false });
};