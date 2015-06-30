using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.GamerServices;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Media;

namespace GraphicsPractical2
{
    public class Game1 : Microsoft.Xna.Framework.Game
    {
        // Often used XNA objects
        private GraphicsDeviceManager graphics;
        private SpriteBatch spriteBatch;
        private FrameRateCounter frameRateCounter;

        // Game objects and variables
        private Camera camera;
        private KeyboardState CurrentKB;
        private KeyboardState PreviousKB;
        private int sceneCounter;
        private SpriteFont Segoe;
        // Model
        private Model model;
        private Texture2D E1,E2,E3,E4;
        private Material modelMaterial;
        private float modelRotation;
        // Quad
        private VertexPositionNormalTexture[] quadVertices;
        private short[] quadIndices;
        private Matrix quadTransform;

        public Game1()
        {
            this.graphics = new GraphicsDeviceManager(this);
            this.Content.RootDirectory = "Content";
            // Create and add a frame rate counter
            this.frameRateCounter = new FrameRateCounter(this);
            this.Components.Add(this.frameRateCounter);
        }

        protected override void Initialize()
        {
            // Copy over the device's rasterizer state to change the current fillMode
            this.GraphicsDevice.RasterizerState = new RasterizerState() { CullMode = CullMode.None };
            // Set up the window
            this.graphics.PreferredBackBufferWidth = 800;
            this.graphics.PreferredBackBufferHeight = 600;
            this.graphics.IsFullScreen = false;
            // Let the renderer draw and update as often as possible
            this.graphics.SynchronizeWithVerticalRetrace = false;
            this.IsFixedTimeStep = false;
            // Flush the changes to the device parameters to the graphics card
            this.graphics.ApplyChanges();
            // Initialize the camera
            this.camera = new Camera(new Vector3(0, 50, 100), new Vector3(0, 0, 0), new Vector3(0, 1, 0));
            modelRotation = 0.0f;
            this.IsMouseVisible = true;
            sceneCounter = 0;
            base.Initialize();
        }

        protected override void LoadContent()
        {
            // Create a SpriteBatch object
            this.spriteBatch = new SpriteBatch(this.GraphicsDevice);
            // Load the "Simple" effect
            Effect effect = this.Content.Load<Effect>("Effects/Simple");
            // Load the model and let it use the "Simple" effect
            this.model = this.Content.Load<Model>("Models/bunny");
            this.model.Meshes[0].MeshParts[0].Effect = effect;
            // Setup the quad
            this.setupQuad();
            // Load the quad texture
            Segoe = this.Content.Load<SpriteFont>("Segoe");
        }

        /// <summary>
        /// Sets up a 2 by 2 quad around the origin.
        /// </summary>
        private void setupQuad()
        {
            float scale = 50.0f;

            // Normal points up
            Vector3 quadNormal = new Vector3(0, 1, 0);

            this.quadVertices = new VertexPositionNormalTexture[4];
            // Top left
            this.quadVertices[0].Position = new Vector3(-1, 0.03f, -1);
            this.quadVertices[0].Normal = quadNormal;
            this.quadVertices[0].TextureCoordinate = new Vector2(0, 0);
            // Top right
            this.quadVertices[1].Position = new Vector3(100, 0.03f, -1);
            this.quadVertices[1].Normal = quadNormal;
            this.quadVertices[1].TextureCoordinate = new Vector2(1, 0);
            // Bottom left
            this.quadVertices[2].Position = new Vector3(-1, 0.03f, 1);
            this.quadVertices[2].Normal = quadNormal;
            this.quadVertices[2].TextureCoordinate = new Vector2(0, 1);
            // Bottom right
            this.quadVertices[3].Position = new Vector3(1, 0.03f, 1);
            this.quadVertices[3].Normal = quadNormal;
            this.quadVertices[3].TextureCoordinate = new Vector2(1, 1);

            this.quadIndices = new short[] { 0, 1, 2, 1, 2, 3 };
            this.quadTransform = Matrix.CreateScale(scale);
        }

        protected override void Update(GameTime gameTime)
        {
            float timeStep = (float)gameTime.ElapsedGameTime.TotalSeconds * 60.0f;
            // Update the window title
            this.Window.Title = "XNA Renderer | FPS: " + this.frameRateCounter.FrameRate;
            //update the rotation
            modelRotation += (float)gameTime.ElapsedGameTime.TotalMilliseconds *
        MathHelper.ToRadians(0.1f);
            PreviousKB = CurrentKB;
            CurrentKB = Keyboard.GetState();
            if (CurrentKB.IsKeyUp(Keys.Space) && PreviousKB.IsKeyDown(Keys.Space))
            {
                sceneCounter += 1;
                if (sceneCounter == 3)
                    sceneCounter = 0;
            }
            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            // Clear the screen in a predetermined color and clear the depth buffer
            this.GraphicsDevice.Clear(ClearOptions.Target | ClearOptions.DepthBuffer, Color.DeepSkyBlue, 1.0f, 0);
            spriteBatch.Begin();
            //Ensures that the world isn't destroyed by spritebatch
            GraphicsDevice.BlendState = BlendState.Opaque;
            GraphicsDevice.DepthStencilState = DepthStencilState.Default;
            GraphicsDevice.SamplerStates[0] = SamplerState.LinearWrap;
            // Get the model's only mesh
            ModelMesh mesh = this.model.Meshes[0];
            Effect effect = mesh.Effects[0];

            // Allows the viewer to switch through the several techniques.
            // Set the effect parameters
            
            if (sceneCounter == 0)
            {
                effect.CurrentTechnique = effect.Techniques["Simple"];
                spriteBatch.DrawString(Segoe, "[E1] Multiple Lights",Vector2.Zero, Color.White);
            }
            else if (sceneCounter == 2)
            {
                effect.CurrentTechnique = effect.Techniques["Cellshading"];
                spriteBatch.DrawString(Segoe, "[E3] CellShading", Vector2.Zero, Color.White);
            }
            else if (sceneCounter == 1)
            {
                effect.CurrentTechnique = effect.Techniques["SpotLight"];
                spriteBatch.DrawString(Segoe, "[E2] Spotlight", Vector2.Zero, Color.White);
            }
            this.camera.SetEffectParameters(effect);
            this.modelMaterial.SetEffectParameters(effect);

            // Matrices for 3D perspective projection
            Matrix WorldMatrix = Matrix.CreateScale(10.0f, 10.0f, 10.0f);

            //Matrix to retain the proper positions for light calculation while the model rotates
            effect.Parameters["tempWorld"].SetValue(WorldMatrix);

            // the rotation matrix
            Matrix Rotate = Matrix.CreateRotationY(modelRotation);

            //the matrix that allows the world to rotate
            WorldMatrix = Rotate * WorldMatrix;

            //the matrix that alters the size of the model and quad
            Matrix Size = Matrix.CreateScale(20.0f, 20.0f, 20.0f);
            effect.Parameters["World"].SetValue(WorldMatrix);
            effect.Parameters["Size"].SetValue(Size);

            // Draw the model
            mesh.Draw();

            foreach (EffectPass pass in effect.CurrentTechnique.Passes)
            {
                pass.Apply();
                GraphicsDevice.DrawUserIndexedPrimitives(PrimitiveType.TriangleList, quadVertices, 0, 4, quadIndices, 0, 2);
            }
            spriteBatch.End();
            base.Draw(gameTime);
        }
    }
}
